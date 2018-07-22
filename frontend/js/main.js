
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
            this.$http.get(this.kanstat_data_url).then(function (response) {
                this.$http.get(this.genres_data_url).then(function (response2) {
                    this.kanstat_data = response.data;
                    this.genres_data = response2.data;
                    this.active_obj_create(this.active_stat);
                    this.loader = false;
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
            this.aobj = [];
            for (var property in this.kanstat_data) {
                if (this.kanstat_data.hasOwnProperty(property)) {
                    if (!this.kanstat_data[property][gid]) {
                        // vm.$set(this.aobj, 0, {
                        //     glyph: "",
                        //     freq: "",
                        //     used: "",
                        // });
                    } else {
                        vm.$set(this.aobj, this.kanstat_data[property]["n" + gid] - 1, {
                            glyph: property,
                            freq: this.kanstat_data[property]["f" + gid],
                            used: this.kanstat_data[property][gid],
                        });
                    }
                }
            }
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
            methods: {
                byars_link: function (kanji) {
                    return "http://e-lib.ua/dic/results?w=" + kanji + "&m=0";
                },
                jisho_link: function (kanji) {
                    return "https://jisho.org/search/" + kanji + "%20%23kanji";
                },
                checkdata: function () {
                    return this.aeobj.length > 0;
                }
            }
        }
    }
})