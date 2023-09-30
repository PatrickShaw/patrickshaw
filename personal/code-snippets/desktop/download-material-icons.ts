#!/usr/bin/env -S deno run
import { basename, dirname, extname } from "https://deno.land/std@0.184.0/path/mod.ts";

await Promise.all(Deno.args.map(async urlString => {
  // E.g. https://fonts.gstatic.com/s/i/materialiconsround/volume_up/v14/24px.svg
  const fileResponse = await fetch(urlString);

  if (fileResponse.body) {
    const iconNamePath = dirname(dirname(urlString));
    const iconName = basename(iconNamePath);
    const ext = extname(urlString);
    const file = await Deno.open(`./assets/icons/material/${iconName}${ext}`, { write: true, create: true });
    await fileResponse.body.pipeTo(file.writable);
    await file.close
  } else {
    console.error('no body for', urlString);
  }
}));
