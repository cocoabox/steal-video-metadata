#!/usr/bin/env node

const axios = require('axios');
const fs = require('fs');
const path = require('path');
const stdin = process.stdin;
const stdout = process.stdout;
const inputChunks = [];

stdin.resume();
stdin.setEncoding('utf8');

stdin.on('data', function (chunk) {
    inputChunks.push(chunk);
});

function sleep(msec) {
    return new Promise(resolve => {
        setTimeout(() => {
            resolve();
        }, msec);
    });
}

function is_dir(dir) {
    try {
        return fs.lstatSync(dir).isDirectory();
    }
    catch (error) {
        return false;
    }
}


function download(url, local_path) {  
    console.warn('download :', url, '=>', local_path);
    return new Promise((resolve, reject) => {
        const dir_path = path.dirname(local_path);
        if (! is_dir(dir_path)) {
            fs.mkdirSync(dir_path, { recursive: true })
        }

        const writer = fs.createWriteStream(local_path);
        const response = axios({
            url,
            method: 'GET',
            responseType: 'stream'
        }).then(response => {
            response.data.pipe(fs.createWriteStream(local_path));
        }).catch(err => {
            console.warn("download error", url, err);
            reject({err});
        });
    });
}



const season_num = process.argv[2] ?? 1;
const download_imgs = (process.argv[3] ?? '').toLowerCase() === 'imgs';

console.warn("SEASON", season_num);

stdin.on('end', async function () {
    const input = JSON.parse(inputChunks.join());
    const files = fs.readdirSync(`season ${season_num}`).filter(name => ! name.match(/\.(nfo|jpg|png|webp)$/)).map(name => {
        const mat = name.match(/^(.*)\.([^\.]+)/);
        if (!mat) return;
        const stripped = mat[1]
            .replaceAll(/\(.*?\)/g, '')
            .replaceAll(/\[.*?\]/g, '')
            .replaceAll(/(4K|4k|720|1080|264|265|10bit|10\-bit)/g, '')
            .replaceAll(/S[0-9]{1,2}/g, '')
            .replaceAll(/Season [0-9]{1,2}/g, '')
            .trim();

        return {name, base: mat[1], stripped};
    }).filter(n => !!n);

    const get_files = cb => {
        let out = [];
        for (let i = files.length-1; i >=0; i--) {
            if (cb(files[i])) {
                out.push(files[i]);
                files.splice(i, 1);
            }
        }
        return out;
    };

    let downed = [];

    const eps = input.episodes;
    eps.sort((a,b)=>b.ep-a.ep);
    const downs = [];
    for (const ep_obj of eps) {
        const {ep,title,synop, img_href} = ep_obj;
        const ep_strs = [ ep < 10 ? '0' + ep : ep , ep + '' ];
        const got_files_2d = [
            get_files(f => f.stripped.indexOf(ep_strs[0]) >= 0),
            get_files(f => f.stripped.indexOf(ep_strs[1]) >= 0),
        ];
        const got_files = got_files_2d.flat().filter( (value, index, self) => self.indexOf(value) === index );

        for (const got of got_files) {
            let thumb_fn;
            if (download_imgs) {
                const img_mat = img_href.replace(/(\?|#).*$/,"").match(/^(.*?)\.([^\.]+)\.([^\.]*)$/);
                if (img_mat) {
                    const img_url_suf = img_mat[1];
                    const img_url_ext = img_mat[3];
                    const img_url = `${img_mat[1]}.${img_mat[3]}`;

                    thumb_fn = `${got.base}.${img_url_ext}`;
                    const img_path = path.join(`season ${season_num}`, thumb_fn); 

                    if (! downed.includes(img_href)) {
                        downed.push(img_href);
                        downs.push( download(img_href, img_path) );
                    }
                }
                else {
                    console.warn('img_href is in unexpected format :', img_href);
                }
            }

            const nfo =[
                '<episodedetails>',
                `<episode>${ep}</episode>`,
                `<displayorder>${ep}</displayorder>`,
                `<name>${ep}. ${title}</name>`,
                `<plot>${synop}</plot>`,
                thumb_fn ? `<thumb>${thumb_fn}</thumb>` : '',
                '</episodedetails>',
            ].join('\n');
            const nfo_fullpath = `season ${season_num}/${got.base}.nfo`;
            console.warn('write :', nfo_fullpath);
            fs.writeFileSync(nfo_fullpath, nfo, 'utf8');
        }

    }
    fs.writeFileSync(path.join(`season ${season_num}`, 'season.nfo'),[
        '<season>',
        `<plot>${input.series_synop}</plot>`,
        '</season>',
    ].join('\n'),'utf8');


    if (downs.length > 0) {
        console.warn('waiting for downloads to complete');
        await Promise.all(downs);
    }

});
