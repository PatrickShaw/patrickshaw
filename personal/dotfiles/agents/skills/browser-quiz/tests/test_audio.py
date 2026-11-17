import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import struct
import tempfile
import sys
import threading
import unittest
import urllib.error
import urllib.request
from unittest.mock import patch

SKILL = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("quiz", SKILL / "scripts" / "quiz.py")
quiz = importlib.util.module_from_spec(SPEC)
with patch.object(sys, "path", [str(SKILL / "scripts"), *sys.path]):
    SPEC.loader.exec_module(quiz)


def create_wav(sample_rate=44100, channels=1, bit_depth=16, duration_ms=100, samples=None):
    """Create minimal valid WAV file bytes."""
    if samples is None:
        samples = (sample_rate * channels * duration_ms) // 1000
    
    byte_rate = sample_rate * channels * bit_depth // 8
    block_align = channels * bit_depth // 8
    
    # Build fmt chunk
    fmt_chunk = struct.pack(
        "<HHIIHH",
        1,  # PCM format
        channels,
        sample_rate,
        byte_rate,
        block_align,
        bit_depth
    )
    fmt_subchunk = b"fmt " + struct.pack("<I", len(fmt_chunk)) + fmt_chunk
    
    # Build data chunk with silence
    data = b"\x00" * (samples * block_align)
    data_subchunk = b"data" + struct.pack("<I", len(data)) + data
    
    # Build RIFF header
    file_size = 4 + len(fmt_subchunk) + len(data_subchunk)
    riff = b"RIFF" + struct.pack("<I", file_size) + b"WAVE"
    
    return riff + fmt_subchunk + data_subchunk


class AudioValidationTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="tmp_rovo_audio_", dir=Path.cwd())
        self.addCleanup(self.temporary.cleanup)
        self.quiz_dir = Path(self.temporary.name)

    def test_valid_mono_wav_passthrough(self):
        """Valid mono WAV passes validation."""
        wav_bytes = create_wav(sample_rate=44100, channels=1, bit_depth=16)
        audio_file = self.quiz_dir / "test.wav"
        audio_file.write_bytes(wav_bytes)
        
        sample_rate, channels, bit_depth = quiz.validate_wav_file(audio_file)
        self.assertEqual(sample_rate, 44100)
        self.assertEqual(channels, 1)
        self.assertEqual(bit_depth, 16)

    def test_valid_stereo_wav(self):
        """Valid stereo WAV passes validation."""
        wav_bytes = create_wav(sample_rate=48000, channels=2, bit_depth=24)
        audio_file = self.quiz_dir / "stereo.wav"
        audio_file.write_bytes(wav_bytes)
        
        sample_rate, channels, bit_depth = quiz.validate_wav_file(audio_file)
        self.assertEqual(sample_rate, 48000)
        self.assertEqual(channels, 2)
        self.assertEqual(bit_depth, 24)

    def test_invalid_wav_not_riff_header(self):
        """Rejects non-RIFF files."""
        bad_file = self.quiz_dir / "bad.wav"
        bad_file.write_bytes(b"JUNK" + b"\x00" * 40)
        
        with self.assertRaisesRegex(ValueError, "missing RIFF header"):
            quiz.validate_wav_file(bad_file)

    def test_invalid_wav_not_wave_format(self):
        """Rejects RIFF files without WAVE format."""
        wav_bytes = b"RIFF" + b"\x00" * 4 + b"JUNK" + b"\x00" * 32
        bad_file = self.quiz_dir / "bad.wav"
        bad_file.write_bytes(wav_bytes)
        
        with self.assertRaisesRegex(ValueError, "missing WAVE format"):
            quiz.validate_wav_file(bad_file)

    def test_invalid_wav_too_short(self):
        """Rejects truncated WAV files."""
        bad_file = self.quiz_dir / "short.wav"
        bad_file.write_bytes(b"RIFF\x00\x00\x00\x00")
        
        with self.assertRaisesRegex(ValueError, "too short"):
            quiz.validate_wav_file(bad_file)

    def test_invalid_wav_unsupported_format(self):
        """Rejects non-PCM audio formats."""
        wav_bytes = create_wav()
        # Modify to use format code 0x0002 (ADPCM)
        modified = bytearray(wav_bytes)
        fmt_pos = 12
        struct.pack_into("<H", modified, fmt_pos + 8, 0x0002)
        
        bad_file = self.quiz_dir / "compressed.wav"
        bad_file.write_bytes(bytes(modified))
        
        with self.assertRaisesRegex(ValueError, "Unsupported audio format"):
            quiz.validate_wav_file(bad_file)

    def test_invalid_wav_unsupported_channels(self):
        """Rejects surround sound or invalid channel counts."""
        for channels in [0, 3, 5, 6]:
            with self.subTest(channels=channels):
                wav_bytes = create_wav(channels=channels)
                bad_file = self.quiz_dir / f"channels_{channels}.wav"
                bad_file.write_bytes(wav_bytes)
                
                with self.assertRaisesRegex(ValueError, "Unsupported channel count"):
                    quiz.validate_wav_file(bad_file)

    def test_invalid_wav_unsupported_sample_rate(self):
        """Rejects unsupported sample rates."""
        for sample_rate in [4000, 200000]:
            with self.subTest(sample_rate=sample_rate):
                wav_bytes = create_wav(sample_rate=sample_rate)
                bad_file = self.quiz_dir / f"rate_{sample_rate}.wav"
                bad_file.write_bytes(wav_bytes)
                
                with self.assertRaisesRegex(ValueError, "Unsupported sample rate"):
                    quiz.validate_wav_file(bad_file)

    def test_invalid_wav_unsupported_bit_depth(self):
        """Rejects unsupported bit depths."""
        for bit_depth in [12, 20, 48]:
            with self.subTest(bit_depth=bit_depth):
                wav_bytes = create_wav(bit_depth=bit_depth)
                bad_file = self.quiz_dir / f"depth_{bit_depth}.wav"
                bad_file.write_bytes(wav_bytes)
                
                with self.assertRaisesRegex(ValueError, "Unsupported bit depth"):
                    quiz.validate_wav_file(bad_file)

    def test_invalid_wav_no_data_chunk(self):
        """Rejects WAV files without data chunk."""
        # Build a WAV with fmt and padding chunks but no data chunk
        fmt_chunk = struct.pack(
            "<HHIIHH",
            1, 1, 44100, 44100 * 1 * 16 // 8, 1 * 16 // 8, 16
        )
        fmt_subchunk = b"fmt " + struct.pack("<I", len(fmt_chunk)) + fmt_chunk
        
        # Add padding to reach minimum file size
        padding = b"PAD " + struct.pack("<I", 6) + b"padding"
        
        # Build RIFF header (no data chunk)
        file_size = 4 + len(fmt_subchunk) + len(padding)
        riff_header = b"RIFF" + struct.pack("<I", file_size)
        riff = riff_header + b"WAVE" + fmt_subchunk + padding
        
        bad_file = self.quiz_dir / "no_data.wav"
        bad_file.write_bytes(riff)
        
        with self.assertRaisesRegex(ValueError, "No data chunk found"):
            quiz.validate_wav_file(bad_file)

    def test_invalid_wav_file_too_large(self):
        """Rejects files exceeding max size."""
        # Create a WAV that is actually too large
        large_wav = create_wav(duration_ms=30 * 1024)  # Create larger file
        
        bad_file = self.quiz_dir / "huge.wav"
        bad_file.write_bytes(large_wav)
        
        with self.assertRaisesRegex(ValueError, "exceeds.*bytes"):
            quiz.validate_wav_file(bad_file, max_bytes=100000)

    def test_invalid_wav_file_not_found(self):
        """Rejects missing files."""
        missing = self.quiz_dir / "missing.wav"
        
        with self.assertRaisesRegex(ValueError, "not found"):
            quiz.validate_wav_file(missing)

    def test_safe_path_rejects_absolute_paths(self):
        """safe_audio_path rejects absolute paths."""
        result = quiz.safe_audio_path("/etc/passwd", self.quiz_dir)
        self.assertIsNone(result)

    def test_safe_path_rejects_traversal(self):
        """safe_audio_path rejects .. traversal."""
        result = quiz.safe_audio_path("../../../etc/passwd", self.quiz_dir)
        self.assertIsNone(result)

    def test_safe_path_rejects_dot_segments(self):
        for path in ["./test.wav", "../test.wav", "audio/./test.wav"]:
            with self.subTest(path=path):
                result = quiz.safe_audio_path(path, self.quiz_dir)
                self.assertIsNone(result)

    def test_safe_path_rejects_backslash(self):
        """safe_audio_path rejects Windows backslash paths."""
        result = quiz.safe_audio_path("audio\\test.wav", self.quiz_dir)
        self.assertIsNone(result)

    def test_safe_path_rejects_url(self):
        """safe_audio_path rejects URLs."""
        result = quiz.safe_audio_path("http://example.com/audio.wav", self.quiz_dir)
        self.assertIsNone(result)

    def test_safe_path_rejects_url_encoded_traversal(self):
        """safe_audio_path rejects URL-encoded traversal."""
        for encoded in ["%2e%2e/test", "%5c%5ctest", "%2ftest"]:
            with self.subTest(encoded=encoded):
                result = quiz.safe_audio_path(encoded, self.quiz_dir)
                self.assertIsNone(result)

    def test_safe_path_rejects_symlink_escape(self):
        """safe_audio_path rejects symlinks that escape quiz_dir."""
        # Create a file outside quiz_dir
        import tempfile as tmp
        outside_dir = Path(tmp.gettempdir()) / "outside_audio_test"
        outside_dir.mkdir(exist_ok=True)
        try:
            outside_file = outside_dir / "external.wav"
            outside_file.write_bytes(b"data")
            
            # Create symlink inside quiz_dir pointing outside
            symlink = self.quiz_dir / "escape.wav"
            symlink.symlink_to(outside_file)
            
            result = quiz.safe_audio_path("escape.wav", self.quiz_dir)
            # The symlink resolves to a path outside quiz_dir, so should be rejected
            self.assertIsNone(result)
        finally:
            import shutil
            shutil.rmtree(outside_dir, ignore_errors=True)

    def test_safe_path_accepts_valid_relative_path(self):
        """safe_audio_path accepts valid relative paths beneath quiz_dir."""
        audio_file = self.quiz_dir / "audio.wav"
        audio_file.write_bytes(b"data")
        
        result = quiz.safe_audio_path("audio.wav", self.quiz_dir)
        self.assertIsNotNone(result)
        self.assertEqual(result, audio_file)

    def test_safe_path_accepts_nested_subdirectory(self):
        """safe_audio_path accepts files in nested subdirectories."""
        subdir = self.quiz_dir / "audio" / "samples"
        subdir.mkdir(parents=True)
        audio_file = subdir / "sample.wav"
        audio_file.write_bytes(b"data")
        
        result = quiz.safe_audio_path("audio/samples/sample.wav", self.quiz_dir)
        self.assertIsNotNone(result)
        self.assertEqual(result, audio_file)

    def test_safe_path_rejects_non_string(self):
        """safe_audio_path rejects non-string inputs."""
        for value in [None, 123, [], {}]:
            with self.subTest(value=value):
                result = quiz.safe_audio_path(value, self.quiz_dir)
                self.assertIsNone(result)


class QuizWithAudioTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="tmp_rovo_audio_quiz_", dir=Path.cwd())
        self.addCleanup(self.temporary.cleanup)
        self.quiz_dir = Path(self.temporary.name)

    def create_example_with_audio(self):
        """Create a quiz definition with optional audio metadata."""
        return {
            "schemaVersion": 2,
            "topic": "audio-test",
            "survey": {
                "title": "Audio Quiz",
                "elements": [
                    {
                        "type": "radiogroup",
                        "name": "question_1",
                        "title": "Test question with audio",
                        "choices": [
                            {"value": "a", "text": "Option A"},
                            {"value": "b", "text": "Option B"}
                        ],
                        "correctAnswer": "a",
                        "audio": {
                            "file": "audio/q1.wav",
                            "sha256": hashlib.sha256(create_wav()).hexdigest(),
                            "transcript": "This is question one.",
                            "pronunciation": "Thɪs ɪz ˈkwɛʃtʃən wʌn",
                            "pronunciationLabel": "IPA",
                            "attribution": "Sample audio"
                        }
                    }
                ]
            },
            "learning": {
                "question_1": {
                    "concept": "test", "skill": "recognition", "difficulty": "intro",
                    "explanation": "Test explanation",
                    "choiceExplanations": {
                        "a": "Correct",
                        "b": "Incorrect"
                    }
                }
            }
        }

    def test_validate_quiz_with_audio_metadata(self):
        """Quiz validation accepts valid audio metadata."""
        definition = self.create_example_with_audio()
        result = quiz.validate_quiz(definition)
        self.assertEqual(result, definition)

    def test_validate_quiz_audio_invalid_file_string(self):
        """Rejects non-string audio file."""
        definition = self.create_example_with_audio()
        definition["survey"]["elements"][0]["audio"]["file"] = 123
        
        with self.assertRaisesRegex(ValueError, "audio.file must be non-empty string"):
            quiz.validate_quiz(definition)

    def test_validate_quiz_audio_invalid_sha256(self):
        """Rejects invalid sha256 hash."""
        definition = self.create_example_with_audio()
        definition["survey"]["elements"][0]["audio"]["sha256"] = "not-64-hex"
        
        with self.assertRaisesRegex(ValueError, "audio.sha256 must be 64 hex"):
            quiz.validate_quiz(definition)

    def test_validate_quiz_audio_invalid_transcript(self):
        """Rejects non-string transcript."""
        definition = self.create_example_with_audio()
        definition["survey"]["elements"][0]["audio"]["transcript"] = 123
        
        with self.assertRaisesRegex(ValueError, "audio.transcript must be non-empty"):
            quiz.validate_quiz(definition)

    def test_validate_quiz_audio_unknown_field(self):
        """Rejects unknown audio fields."""
        definition = self.create_example_with_audio()
        definition["survey"]["elements"][0]["audio"]["unknown"] = "value"
        
        with self.assertRaisesRegex(ValueError, "audio has unknown fields"):
            quiz.validate_quiz(definition)

    def test_validate_quiz_audio_is_not_object(self):
        """Rejects non-object audio."""
        definition = self.create_example_with_audio()
        definition["survey"]["elements"][0]["audio"] = "string"
        
        with self.assertRaisesRegex(ValueError, "audio must be an object"):
            quiz.validate_quiz(definition)

    def test_load_audio_valid_files(self):
        """load_audio loads valid WAV files."""
        definition = self.create_example_with_audio()
        wav_bytes = create_wav()
        
        # Create audio directory and file
        audio_dir = self.quiz_dir / "audio"
        audio_dir.mkdir()
        audio_file = audio_dir / "q1.wav"
        audio_file.write_bytes(wav_bytes)
        
        # Add sha256 to definition
        computed_hash = hashlib.sha256(wav_bytes).hexdigest()
        definition["survey"]["elements"][0]["audio"]["sha256"] = computed_hash
        
        audio_map = quiz.load_audio(definition, self.quiz_dir)
        self.assertIn("question_1", audio_map)
        self.assertEqual(audio_map["question_1"], wav_bytes)

    def test_load_audio_hash_mismatch(self):
        """load_audio rejects files with hash mismatch."""
        definition = self.create_example_with_audio()
        wav_bytes = create_wav()
        
        audio_dir = self.quiz_dir / "audio"
        audio_dir.mkdir()
        audio_file = audio_dir / "q1.wav"
        audio_file.write_bytes(wav_bytes)
        
        # Set wrong hash
        definition["survey"]["elements"][0]["audio"]["sha256"] = "0" * 64
        
        with self.assertRaisesRegex(ValueError, "hash mismatch"):
            quiz.load_audio(definition, self.quiz_dir)

    def test_load_audio_file_not_found(self):
        """load_audio rejects missing files."""
        definition = self.create_example_with_audio()
        
        with self.assertRaisesRegex(ValueError, "audio/q1.wav"):
            quiz.load_audio(definition, self.quiz_dir)

    def test_load_audio_invalid_path(self):
        """load_audio rejects invalid paths."""
        definition = self.create_example_with_audio()
        definition["survey"]["elements"][0]["audio"]["file"] = "../etc/passwd"
        
        with self.assertRaisesRegex(ValueError, "invalid audio file path"):
            quiz.load_audio(definition, self.quiz_dir)

    def test_all_audio_fields_are_required_except_label(self):
        for key in ("file", "sha256", "transcript", "pronunciation", "attribution"):
            with self.subTest(key=key):
                definition = self.create_example_with_audio()
                del definition["survey"]["elements"][0]["audio"][key]
                with self.assertRaisesRegex(ValueError, "missing required"):
                    quiz.validate_quiz(definition)

    def test_text_questions_do_not_require_audio_files(self):
        definition = self.create_example_with_audio()
        del definition["survey"]["elements"][0]["audio"]
        self.assertEqual(quiz.load_audio(definition, self.quiz_dir), {})

    def test_public_survey_without_audio(self):
        """public_survey works without audio metadata."""
        definition = self.create_example_with_audio()
        del definition["survey"]["elements"][0]["audio"]
        
        payload = quiz.public_survey(definition)
        self.assertNotIn("questionAudio", payload)
        self.assertEqual(payload["title"], "Audio Quiz")

    def test_public_survey_with_audio_projection(self):
        """public_survey projects audio metadata safely."""
        definition = self.create_example_with_audio()
        audio_map = {"question_1": b"ignored"}  # Content ignored, just marks presence
        
        payload = quiz.public_survey(definition, audio_map)
        self.assertIn("questionAudio", payload)
        self.assertIn("question_1", payload["questionAudio"])
        
        audio_info = payload["questionAudio"]["question_1"]
        self.assertEqual(audio_info["transcript"], "This is question one.")
        self.assertEqual(audio_info["pronunciation"], "Thɪs ɪz ˈkwɛʃtʃən wʌn")
        self.assertEqual(audio_info["pronunciationLabel"], "IPA")
        self.assertEqual(audio_info["attribution"], "Sample audio")
        self.assertEqual(audio_info["url"], "audio/question_1")

    def test_public_survey_no_answer_key_in_audio(self):
        """public_survey never leaks file paths or answer keys in audio."""
        definition = self.create_example_with_audio()
        audio_map = {"question_1": b"data"}
        
        payload_json = json.dumps(quiz.public_survey(definition, audio_map))
        self.assertNotIn("correctAnswer", payload_json)
        self.assertNotIn("sha256", payload_json)
        self.assertNotIn("audio/q1.wav", payload_json)
        self.assertNotIn("file", payload_json)

    def test_public_survey_pronunciation_label_default(self):
        """public_survey uses default pronunciationLabel."""
        definition = self.create_example_with_audio()
        del definition["survey"]["elements"][0]["audio"]["pronunciationLabel"]
        audio_map = {"question_1": b"data"}
        
        payload = quiz.public_survey(definition, audio_map)
        self.assertEqual(payload["questionAudio"]["question_1"]["pronunciationLabel"], "Show pronunciation")

    def test_public_survey_omits_optional_audio_fields(self):
        """public_survey omits absent optional audio fields."""
        definition = self.create_example_with_audio()
        # Keep only required fields
        audio_obj = definition["survey"]["elements"][0]["audio"]
        for key in list(audio_obj.keys()):
            if key != "file":
                del audio_obj[key]
        
        audio_map = {"question_1": b"data"}
        payload = quiz.public_survey(definition, audio_map)
        
        audio_info = payload["questionAudio"]["question_1"]
        self.assertNotIn("transcript", audio_info)
        self.assertNotIn("pronunciation", audio_info)
        self.assertNotIn("attribution", audio_info)
        self.assertIn("pronunciationLabel", audio_info)  # Always present
        self.assertIn("url", audio_info)  # Always present


class HTTPAudioTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="tmp_rovo_audio_http_", dir=Path.cwd())
        self.addCleanup(self.temporary.cleanup)
        self.directory = Path(self.temporary.name)
        
        # Create definition with audio
        self.definition = {
            "schemaVersion": 2,
            "topic": "audio-test",
            "survey": {
                "title": "Audio HTTP Test",
                "elements": [
                    {
                        "type": "radiogroup",
                        "name": "q1",
                        "title": "Question 1",
                        "choices": [
                            {"value": "a", "text": "A"},
                            {"value": "b", "text": "B"}
                        ],
                        "correctAnswer": "a",
                        "audio": {
                            "transcript": "Question text",
                            "file": "q1.wav"
                        }
                    }
                ]
            },
            "learning": {
                "q1": {
                    "concept": "test", "skill": "test", "difficulty": "test",
                    "explanation": "Test",
                    "choiceExplanations": {"a": "Yes", "b": "No"}
                }
            }
        }
        
        # Create audio file
        wav_bytes = create_wav()
        audio_file = self.directory / "q1.wav"
        audio_file.write_bytes(wav_bytes)
        self.wav_bytes = wav_bytes
        
        # Create session with audio
        audio_map = {"q1": wav_bytes}
        self.session = quiz.QuizSession(self.definition, self.directory, audio_map)
        self.server = quiz.ThreadingHTTPServer(("127.0.0.1", 0), quiz.handler_for(self.session, self.directory))
        threading.Thread(target=self.server.serve_forever, daemon=True).start()
        self.addCleanup(self.server.server_close)
        self.addCleanup(self.server.shutdown)
        self.origin = f"http://127.0.0.1:{self.server.server_port}"
        self.url = f"{self.origin}/{self.session.token}/"

    def test_audio_get_without_range(self):
        """GET audio without Range returns full file."""
        with urllib.request.urlopen(self.url + "audio/q1") as response:
            self.assertEqual(response.status, 200)
            self.assertEqual(response.headers.get("Content-Type"), "audio/wav")
            self.assertIn("Accept-Ranges", response.headers)
            data = response.read()
        
        self.assertEqual(data, self.wav_bytes)

    def test_audio_get_with_range_start_end(self):
        """GET audio with Range: bytes=start-end returns 206 partial."""
        start, end = 100, 199
        request = urllib.request.Request(
            self.url + "audio/q1",
            headers={"Range": f"bytes={start}-{end}"}
        )
        with urllib.request.urlopen(request) as response:
            self.assertEqual(response.status, 206)
            self.assertEqual(response.headers.get("Content-Range"), f"bytes {start}-{end}/{len(self.wav_bytes)}")
            data = response.read()
        
        self.assertEqual(data, self.wav_bytes[start:end + 1])

    def test_audio_get_with_range_open_ended(self):
        """GET audio with Range: bytes=start- returns from start to end."""
        start = 100
        request = urllib.request.Request(
            self.url + "audio/q1",
            headers={"Range": f"bytes={start}-"}
        )
        with urllib.request.urlopen(request) as response:
            self.assertEqual(response.status, 206)
            data = response.read()
        
        self.assertEqual(data, self.wav_bytes[start:])

    def test_audio_get_with_suffix_range(self):
        """GET audio with Range: bytes=-suffix returns last N bytes."""
        suffix = 50
        request = urllib.request.Request(
            self.url + "audio/q1",
            headers={"Range": f"bytes=-{suffix}"}
        )
        with urllib.request.urlopen(request) as response:
            self.assertEqual(response.status, 206)
            data = response.read()
        
        self.assertEqual(data, self.wav_bytes[-suffix:])

    def test_audio_get_with_invalid_range(self):
        """GET audio with invalid Range returns 416."""
        request = urllib.request.Request(
            self.url + "audio/q1",
            headers={"Range": "bytes=invalid"}
        )
        with self.assertRaises(urllib.error.HTTPError) as error:
            urllib.request.urlopen(request)
        
        self.assertEqual(error.exception.code, 416)
        error.exception.close()

    def test_audio_get_missing_question(self):
        """GET audio for missing question returns 404."""
        with self.assertRaises(urllib.error.HTTPError) as error:
            urllib.request.urlopen(self.url + "audio/nonexistent")
        
        self.assertEqual(error.exception.code, 404)
        error.exception.close()

    def test_audio_head_request(self):
        """HEAD audio returns headers without body."""
        request = urllib.request.Request(self.url + "audio/q1")
        request.get_method = lambda: "HEAD"
        with urllib.request.urlopen(request) as response:
            self.assertEqual(response.status, 200)
            self.assertEqual(response.headers.get("Content-Type"), "audio/wav")
            # HEAD should have no body
            data = response.read()
        
        self.assertEqual(data, b"")

    def test_audio_head_with_range(self):
        """HEAD audio with Range returns correct headers."""
        request = urllib.request.Request(
            self.url + "audio/q1",
            headers={"Range": "bytes=10-99"}
        )
        request.get_method = lambda: "HEAD"
        with urllib.request.urlopen(request) as response:
            self.assertEqual(response.status, 206)
            self.assertEqual(response.headers.get("Content-Range"), f"bytes 10-99/{len(self.wav_bytes)}")
        
        # Verify no body sent
        data = response.read()
        self.assertEqual(data, b"")

    def test_quiz_payload_includes_audio_metadata(self):
        """GET /quiz includes questionAudio with metadata."""
        with urllib.request.urlopen(self.url + "quiz") as response:
            payload = json.load(response)
        
        self.assertIn("questionAudio", payload)
        self.assertIn("q1", payload["questionAudio"])
        self.assertEqual(payload["questionAudio"]["q1"]["transcript"], "Question text")
        self.assertEqual(payload["questionAudio"]["q1"]["url"], "audio/q1")

    def test_quiz_payload_no_file_paths_or_hashes(self):
        """GET /quiz never leaks file paths or hashes in audio metadata."""
        with urllib.request.urlopen(self.url + "quiz") as response:
            payload_json = json.dumps(json.load(response))
        
        self.assertNotIn("q1.wav", payload_json)
        self.assertNotIn("sha256", payload_json)
        self.assertNotIn("file", payload_json)


class AudioBoundaryTests(unittest.TestCase):
    def test_rejects_empty_and_truncated_pcm_data(self):
        for data in (create_wav(samples=0), create_wav()[:-2]):
            with self.subTest(length=len(data)), self.assertRaises(ValueError):
                quiz.validate_wav_bytes(data)

    def test_allows_padded_odd_length_metadata_chunk(self):
        original = create_wav()
        chunk = b"JUNK" + struct.pack("<I", 1) + b"x\x00"
        data = bytearray(original[:12] + chunk + original[12:])
        struct.pack_into("<I", data, 4, len(data) - 8)
        self.assertEqual(quiz.validate_wav_bytes(bytes(data)), (44100, 1, 16))

    def test_rejects_overstated_data_length(self):
        data = bytearray(create_wav())
        struct.pack_into("<I", data, 40, len(data))
        with self.assertRaisesRegex(ValueError, "Truncated WAV chunk"):
            quiz.validate_wav_bytes(bytes(data))

    def test_range_boundaries(self):
        cases = {None: (0, 99), "bytes=4-": (4, 99), "bytes=0-999": (0, 99),
                 "bytes=-999": (0, 99), "bytes=-2": (98, 99), "bytes=4-8": (4, 8)}
        for header, expected in cases.items():
            with self.subTest(header=header):
                self.assertEqual(quiz.audio_range(header, 100), expected)
        for header in ("bytes=-0", "bytes=100-", "bytes=9-8", "bytes=1-2-3", "bytes=0-1,4-5", "bytes=", "bytes=-"):
            with self.subTest(header=header), self.assertRaises(ValueError):
                quiz.audio_range(header, 100)

    def test_invalid_filename_schema(self):
        for name in ("../a.wav", "/a.wav", "a.mp3", "C:/a.wav", "audio/a%20b.wav", "audio//a.wav", "https://example.org/a.wav"):
            with self.subTest(name=name):
                self.assertFalse(quiz.valid_audio_filename(name))


if __name__ == "__main__":
    unittest.main()
