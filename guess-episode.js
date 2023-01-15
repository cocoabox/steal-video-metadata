#!/usr/bin/env node
//
// guess episode and season from filename
// usage: node guess-episode <FULL_PATH_OF_MP4_FILE>
//
// prints "null" or '{"season":NUMBER_OR_NULL,"ep":NUMBER_OR_NULL}
//
const path = require('path');
const input_path = process.argv[2];

function extract_season_episode(input) {
    // 紛らわしい要素を除去
    let nom = path.basename(input)
        .replace(/(\.[^\.]+)$/, '')        // filename ext
        .replace(/^(\[.*?\])/, '')         // 冒頭の [xxxx]
        .replaceAll(/\[[A-F,0-9]+\]/g, '') // e.g. [FFFF1111]
        .replaceAll(/\(.*?\)/g, '')        // ()括弧
        .replaceAll(/(4k|1044|1920|1080|720|480|264|265|[0-9]+[\s\-]*bit|ac3)/ig, '')
        .trim();

    let season = null;
    let ep;
    const season_mat = nom.match(/season\s*([0-9]+)/i);
    if (season_mat) {
        season = parseInt(season_mat[1]);
        nom = nom.replaceAll(/season\s*([0-9]+)/gi, '');
    }
    const ep_mat = nom.match(/(ep|episode)\s*([0-9]+)/i);
    if (ep_mat) {
        ep = parseInt(ep_mat[2]);
        nom = nom.replaceAll(/(ep|episode)\s*([0-9]+)/gi, '');
    }
    if (ep) {
        return {season, ep};
    }
    const mat = nom.match(/(S([0-9]+))?E([0-9]+)/i);
    if (mat) {
        return {season: parseInt(mat[2]), ep: parseInt(mat[1])};
    }
    const mat1 = nom.match(/([0-9]+)話/);
    if (mat1) {
        return {season, ep: parseInt(mat1[1])};
    }
    const mat2 = nom.match(/\[([0-9]+)\]/);
    if (mat2) {
        return {season, ep: parseInt(mat2[1])};
    }
    const mat3 = nom.match(/([0-9]{2})/);
    if (mat3) {
        return {season, ep: parseInt(mat3[1])};
    }
    const mat4 = nom.match(/([0-9]+)/);
    if (mat4) {
        return {season, ep: parseInt(mat4[1])};
    }    
    return null;
}

console.log(JSON.stringify(extract_season_episode(input_path)));

