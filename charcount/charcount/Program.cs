using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;

namespace charcount
{
    class Program
    {
        static string data_dir, result_dir;
        static int progress = 0;
        static Regex ch_name_rx = new Regex(@"(?<g>\d+)_(?<id>\w+)_(?<n>\d+)\.txt");
        static Dictionary<string, Dictionary<string, int>> result = new Dictionary<string, Dictionary<string, int>>();
        static Dictionary<string, int> total_count = new Dictionary<string, int>();
        static Dictionary<string, Dictionary<string,string>> examples = new Dictionary<string, Dictionary<string, string>>();

        static void Main(string[] args)
        {
            init_env();

            var dinf = new DirectoryInfo(data_dir).GetFiles("*.txt");
            int di = dinf.Length;
            int curr = 0;
            foreach (var file in dinf)
            {
                curr++;
                progress_log(curr, di);

                Match ch_name_mc = ch_name_rx.Match(file.Name);
                string chapter_id = ch_name_mc.Groups["id"].Value;
                string chapter_genre = ch_name_mc.Groups["g"].Value;
                int g_total = 0;

                string chapter = File.ReadAllText(file.FullName);
                foreach(char c in chapter)
                {
                    if (c < '\u4E00' || c > '\u9FD5') continue;
                    string s = c.ToString();

                    AddExamples(chapter_id, chapter, s);

                    if (!result.ContainsKey(s))
                    {
                        result.Add(s, new Dictionary<string, int>());
                        result[s].Add("0", 0);
                    }

                    if (!result[s].ContainsKey(chapter_genre))
                        result[s].Add(chapter_genre, 0);

                    result[s][chapter_genre]++;
                    result[s]["0"]++;
                    g_total++;
                }
                if (!total_count.ContainsKey(chapter_genre))
                    total_count.Add(chapter_genre, 0);
                total_count[chapter_genre] += g_total;
                total_count["0"] += g_total;
            }

            Console.Write("Scan complete. Reformating.");
            result_reformat();

            JObject o = JObject.FromObject(result);
            foreach (var glypf in result)
            {
                foreach(var st in glypf.Value)
                {
                    if (!total_count.ContainsKey(st.Key)) continue;
                    float freq = ((float)st.Value / (float)total_count[st.Key]) * (float)100;
                    string freq_str = String.Format("{0}", freq.ToString("0.00000"));
                    if (freq < 0.00001) freq_str = "< " + (0.00001).ToString("0.00000");
                    o[glypf.Key]["f" + st.Key] = freq_str;
                }
            }

            string json = JsonConvert.SerializeObject(o, Formatting.Indented);
            string result_file = result_dir + @"\stats.json";
            string result_file_min = result_dir + @"\stats.min.json";
            string examples_dir = result_dir + @"\examples\";
            if (File.Exists(result_file)) File.Delete(result_file);
            if (File.Exists(result_file_min)) File.Delete(result_file_min);
            if (!Directory.Exists(examples_dir)) Directory.CreateDirectory(examples_dir);
            File.WriteAllText(result_file, json);
            File.WriteAllText(result_file_min, JsonConvert.SerializeObject(o, Formatting.None));
            foreach(var kanexample in examples)
            {
                File.WriteAllText(examples_dir + kanexample.Key +".json", 
                    JsonConvert.SerializeObject(JObject.FromObject(kanexample.Value), Formatting.None));
            }
        }

        static void AddExamples(string cid, string chapter, string c)
        {
            if (examples.ContainsKey(c)) {
                if (examples[c].ContainsKey(cid)) return;
            }
            else
            {
                examples.Add(c, new Dictionary<string, string>());
            }

            if (examples[c].Count >= 20) return;

            Regex lineRx = new Regex(@"^.+?$");
            foreach(var line in Regex.Split(chapter, "\r\n|\r|\n"))
            {
                if (!line.Contains(c)) continue;
                examples[c].Add(cid, line);
                return;
            }
        }

        static void result_reformat()
        {
            foreach(var g_count in total_count)
            {
                var recounter = new Dictionary<string, int>();
                foreach (var glypf in result)
                {
                    if (!glypf.Value.ContainsKey(g_count.Key))
                    {
                        result[glypf.Key].Add(g_count.Key, 0);
                        recounter.Add(glypf.Key, 0);
                    }
                    else
                    {
                        recounter.Add(glypf.Key, glypf.Value[g_count.Key]);
                    }
                }
                var sortedDict = from entry in recounter orderby entry.Value descending select entry;
                int sd_count = 0;
                foreach (var sd in sortedDict)
                {
                    sd_count++;
                    result[sd.Key]["n" + g_count.Key] = sd_count;
                }
            }
        }

        static void progress_log(int current, int all)
        {
            int percent = current / all;
            if (progress != percent)
            {
                progress = percent;
                Console.WriteLine("Progress: {0}%",progress);
            }
        }

        static void init_env()
        {
            string default_data_dir = Environment.CurrentDirectory + @"\data\";
            string default_result_dir = Environment.CurrentDirectory + @"\result\";
            Console.ForegroundColor = ConsoleColor.White;
            Console.Title = "Kanji Stats - Character counter";
            Console.WriteLine("Путь до директории data ({0}):", default_data_dir);
            data_dir = Console.ReadLine();
            if (data_dir.Length < 3)
                data_dir = default_data_dir;
            Console.WriteLine("Путь до директории result ({0}):", default_result_dir);
            result_dir = Console.ReadLine();
            if (result_dir.Length < 3)
                result_dir = default_result_dir;
            total_count.Add("0", 0);
        }
    }
}
