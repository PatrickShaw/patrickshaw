# SurveyJS

The runner uses the MIT-licensed SurveyJS Form Library, not the paid Survey Creator, Dashboard or PDF products.

- [Source and licence](https://github.com/surveyjs/survey-library/blob/master/LICENSE)
- [Standalone API](https://surveyjs.io/form-library/documentation/get-started-html-css-javascript)
- Packages: `survey-core` and `survey-js-ui`, pinned to 3.2.5.
- Browser assets are downloaded on first use from jsDelivr and verified against SHA-256 hashes in `scripts/quiz.py`. No remote assets are loaded by the quiz page.
- Updating versions requires checking upstream API changes, updating all three hashes together and rerunning browser tests. Don't replace the pinned URLs with `latest`.

MIT License

Copyright (c) 2015-2026 Devsoft Baltic OÜ - http://surveyjs.io/

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
