#!/usr/bin/env deno
import { writableStreamFromWriter } from "https://deno.land/std@0.128.0/streams/mod.ts";
import { extname } from "https://deno.land/std@0.128.0/path/mod.ts";

await Deno.mkdir("./wallpapers/wallhaven", { recursive: true });
const text = await Deno.readTextFile('./wallhaven-backgrounds.txt');
const ids = text.split("\n").filter((line) => /\w/.test(line));

for (const id of ids) {
    try {
        // See: https://wallhaven.cc/help/api
        const url = `https://wallhaven.cc/api/v1/w/${id}`;
        const response =  await fetch(url);
        const json: any = await response.json();
        const data=  json.data;

        const ext = extname(data.path);
        const imagePath = `./wallpapers/wallhaven/${id}${ext}`;
        const imageFile = await Deno.open(imagePath, { write: true, create: true });
        const imageResponse = await fetch(data.path);
        const imageWriteStream = writableStreamFromWriter(imageFile);
        await imageResponse.body!.pipeTo(imageWriteStream);
        console.log(`Saved wallpaper: ${imagePath}`);
    } catch(err) {
        console.error(`Failed to retrieve ${id}`, err);
    }

    // Have to wait a little bit. Wallhaven doesn't like too many requests at once (you'll get an HTTP 429 error)
    await new Promise(resolve => setTimeout(resolve, 1000));
}