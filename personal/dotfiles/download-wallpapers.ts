#!/usr/bin/env deno
import { writableStreamFromWriter } from "https://deno.land/std@0.128.0/streams/mod.ts";
import { extname } from "https://deno.land/std@0.128.0/path/mod.ts";
import { existsSync } from "https://deno.land/std/fs/mod.ts";

await Deno.mkdir("./wallpapers/wallhaven", { recursive: true });
const text = await Deno.readTextFile('./wallhaven-backgrounds.txt');
const ids = new Set(text.split("\n").filter((line) => /\w/.test(line)));
for (const id of ids) {
    try {
        // See: https://wallhaven.cc/help/api
        const url = `https://wallhaven.cc/api/v1/w/${id}`;
        let retries = 0;
        while(true) {
            const response =  await fetch(url);
            if (response.status === 429) {
                const timeout = 500 * (2 ** retries);
                console.log(`too many requests, waiting for ${timeout}ms`);
                await new Promise(resolve => setTimeout(resolve, ));
                retries++;
                continue;
            }
            if (!response.headers.get('content-type')?.includes('application/json')) {
                console.log(`Received unexpected content type ${response.headers.get('content-type')}. Response was: `, response.status, response.statusText, await response.text());
                break;
            }
            const json: any = await response.json();
            const data=  json.data;
    
            const ext = extname(data.path);
            const imagePath = `./wallpapers/wallhaven/${id}${ext}`;
    
            if (existsSync(imagePath)) {
                console.log(`Skipping ${id} because it already exists as ${imagePath}`)
                break;
            }
            
            const imageFile = await Deno.open(imagePath, { write: true, create: true });
            const imageResponse = await fetch(data.path);
            const imageWriteStream = writableStreamFromWriter(imageFile);
            await imageResponse.body!.pipeTo(imageWriteStream);
            console.log(`Saved wallpaper: ${imagePath}`);
        }
    } catch(err) {
        console.error(`Failed to retrieve ${id}`, err);
    }
}