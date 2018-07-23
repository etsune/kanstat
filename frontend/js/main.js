
var vm = new Vue({
    el: '#app',
    data: {
        kanstat_data_url: "https://raw.githubusercontent.com/etsune/kanstat/master/result/stats.min.json",
        genres_data_url: "https://raw.githubusercontent.com/etsune/kanstat/master/result/genres.json",
        genres_data: {},
        kanstat_data: {},
        active_stat: 0,
        aobj: [],
        loader: true,
    },
    methods: {
        loading: function () {
            this.loader = true;
            this.$http.get(this.kanstat_data_url).then(function (response) {
                this.$http.get(this.genres_data_url).then(function (response2) {
                    this.kanstat_data = response.data;
                    this.genres_data = response2.data;
                    this.active_obj_create(this.active_stat);
                }, function (error2) {
                });
            }, function (error) {
            });
        },
        is_active: function (gid) {
            return { 'active': gid == this.active_stat }
        },
        go_to: function (gid) {
            this.active_stat = gid
            this.active_obj_create(gid);
        },
        active_obj_create: function (gid) {
            this.loader = true;
            aobj = [];
            for (var property in this.kanstat_data) {
                if (this.kanstat_data.hasOwnProperty(property)) {
                    if (this.kanstat_data[property][gid]) {
                        aobj[this.kanstat_data[property]["n" + gid] - 1] = {
                            glyph: property,
                            freq: this.kanstat_data[property]["f" + gid],
                            used: this.kanstat_data[property][gid],
                        }
                    }
                }
            }
            this.aobj = aobj;
            this.loader = false;
        }
    },
    created: function () {
        this.loading();
    },
    components: {
        test: {
            template: '#ad-nav',
            data: function () {
                return {
                    searching: testjson,
                }
            },
            props: {
                nviewer: 0,
            },
        },
        kantable: {
            template: '#kantable',
            props: ['activestat', 'aeobj'],
            data: function () {
                return {
                    busy: false,
                    defel: 1,
                }
            },
            watch: {
                activestat: function (newd, oldd) {
                    this.defel = 1
                }
            },
            computed: {
                showob: function () {
                    if (this.aeobj.length > 0) {
                        var new_obj = [];
                        for (var j = this.defel * 100, i = j - 100; i < j; i++) {
                            if (this.aeobj[i] == null){
                                return new_obj;
                            }
                            new_obj[i] = this.aeobj[i];
                        }
                        return new_obj;
                    } else {
                        return []
                    }
                },
                pagescount: function () {
                    return Math.ceil(this.aeobj.length / 100);
                }
            },
            methods: {
                byars_link: function (kanji) {
                    return "http://e-lib.ua/dic/results?w=" + kanji + "&m=0";
                },
                jisho_link: function (kanji) {
                    return "https://jisho.org/search/" + kanji + "%20%23kanji";
                },
                checkdata: function () {
                    return this.aeobj.length > 0;
                },
                change_page: function (page) {
                    this.defel = page
                }
            },
            components: {
                pages: {
                    template: '#pagination',
                    props: ['pagestotal', 'current'],
                    methods: {
                        pagestyle: function (p) {
                            return {active: p == this.current};
                        },
                        hasItem: function (item) {
                            return this.pages.indexOf(item) !== -1
                        }
                    },
                    computed: {
                        range: function () {
                            return 4;
                        },
                        rStart: function () {
                            var s = this.current - this.range
                            return (s > 1) ? s : 1
                        },
                        rEnd: function () {
                            var pt = this.pagestotal
                            var e = this.current + this.range
                            return (e < pt) ? e : pt
                        },
                        pages: function () {
                            var pages = []
                            for (i = this.rStart; i <= this.rEnd; i++) {
                                pages.push(i)
                            }
                            return pages
                        }
                    }
                }
            }
        }
    }
})