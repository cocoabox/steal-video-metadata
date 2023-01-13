(async () => {
    const download = (filename, text) => {
        var element = document.createElement('a');
        element.setAttribute('href', 'data:text/plain;charset=utf-8,' + encodeURIComponent(text));
        element.setAttribute('download', filename);
        element.style.display = 'none';
        document.body.appendChild(element);
        element.click();
        document.body.removeChild(element);
    };
    const getters = [
        {
            domain: 'www.b-ch.com',
            func: async () => {

                const title = window.location.href.match(/\/titles\/(.*?)\/?$/)?.[1];
                if (! title) {
                    alert('cannot get title from URL ; not bandai ch page ??');
                    return;
                }
                const img_dir = `https://image2.b-ch.com/ttl2/${title}/`
                const json = await jQuery.getJSON(`https://www.b-ch.com/json/titles/${title}.json`);
                console.log(json);
                const episodes = json.map(j => {
                    return {
                        ep: j.stry_sq,
                        title: `${j.strysu_txt} ${j.strytitle_txt}`,
                        synop: j.outline1_txt ?? j.outline2_txt,
                        img_href: `${img_dir}/${j.thumnail1file_txt}`,
                    };
                });
                const series_title = $('#bch-summary .bch-c-heading-2__ttl').text();
                const series_synop = $('#bch-summary .bch-p-heading-mov__detail p').clone()    
                    .children() 
                    .remove()   
                    .end()  
                    .text()
                    .trim();

                return {series_title, json: JSON.stringify({series_title, series_synop, episodes})};
            }
        },
        {
            domain: 'animestore.docomo.ne.jp',
            func: async () => {
                const series_title = $('.information h1') 
                    .clone()    
                    .children() 
                    .remove()   
                    .end()  
                    .text()
                    .trim();
                const series_synop = $('.outlineContainer p')  .clone()    
                    .children() 
                    .remove()   
                    .end()  
                    .text()
                    .trim();

                const urls = Array.prototype.slice.call( document.querySelectorAll('[id^="episodePartId"]') ).map(  n => n.href.match(/partId=([0-9]+)/)?.[1]).filter( n => !!n ).map(partId => `https://animestore.docomo.ne.jp/animestore/rest/WS030101?partId=${partId}`);
                const jsons = [];
                for (const [ord, url] of Object.entries(urls)) {
                    const json = await jQuery.getJSON(url);
                    jsons.push( {ord, json } );
                }
                const episodes = jsons.map(({ord, json}) => { return {
                    ep: 1+parseInt(ord),
                    title: `${json.partDispNumber}. ${json.partTitle}`,
                    synop: json.partExp, 
                    img_href: json.mainScenePath,
                }; });
                return {series_title, json: JSON.stringify({series_title, series_synop, episodes})};

            },
        },
        {
            domain: 'www.amazon.co.jp',
            func: async () => {
                const series_title = document.querySelector('[data-automation-id="title"]')?.innerText.trim();
                const series_synop = document.querySelector('[data-automation-id="atf-synopsis"]')?.innerText.trim();

                const li_arr = document.querySelectorAll('[id^="av-ep-episodes"]');
                let episodes = [];
                for (const li of li_arr) {
                    const title_elem = 
                        li.querySelector('[data-automation-id^="ep-title-episodes-"] .js-episode-title-name')
                        ?? 
                        li.querySelector('[data-automation-id^="ep-title-episodes-"]');
                    const title_all = title_elem.innerText.trim();
                    console.log(title_all);
                    const title_mat = title_all.match(/^([0-9]+)\.*\s*(.*)$/);
                    if (! title_mat) {
                        console.warn("failed to match title :", title_all);
                    }
                    const ep = parseFloat(title_mat[1].trim() ?? -1);
                    const title = title_mat[2].trim();
                    const synop_elem = li.querySelector('[data-automation-id^="synopsis-"]');
                    const synop = synop_elem.innerText.trim();

                    const img = li.querySelector('img');
                    const img_href = img?.src;
                    episodes.push({ep, title, synop, img_href});
                }
                return {series_title, json: JSON.stringify({series_title, series_synop, episodes})};

            },
        },
    ];

    const {json, series_title} = (await getters.find(g => g.domain === window.location.host)?.func()) ?? {};
    if (! json) {
        window.alert('invalid domain (supported : ' + getters.map(g => g.domain).join(',') + ')');
        return;
    }

    download(`${series_title}.json.txt`, json);
    const win = window.open();
    win.document.write(json);
})();
