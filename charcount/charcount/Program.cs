using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.IO;
using System.Text.RegularExpressions;

namespace charcount
{
    class Program
    {
        static string data_dir, result_dir;
        static Regex ch_name_rx = new Regex(@"(?<g>\d+)_(?<id>\w+)_(?<n>\d+)\.txt");
        static Dictionary<string, Dictionary<string, int>> result = new Dictionary<string, Dictionary<string, int>>();

        static void Main(string[] args)
        {
            init_env();

            foreach(var file in new DirectoryInfo(data_dir).GetFiles("*.txt"))
            {
                Match ch_name_mc = ch_name_rx.Match(file.Name);
                string chapter_id = ch_name_mc.Groups["id"].Value;
                string chapter_genre = ch_name_mc.Groups["g"].Value;
                string chapter = File.ReadAllText(file.FullName);
                foreach(char c in chapter)
                {
                    if (c < '\u4E00' || c > '\u9FD5') continue;
                    string s = c.ToString();

                    if (!result.ContainsKey(s))
                    {
                        result.Add(s, new Dictionary<string, int>());
                        result[s].Add("0", 0);
                    }

                    if (!result[s].ContainsKey(chapter_genre))
                        result[s].Add(chapter_genre, 0);

                    result[s][chapter_genre]++;
                    result[s]["0"]++;
                }
            }

            string json = JsonConvert.SerializeObject(result, Formatting.Indented);

            string result_file = result_dir + @"\stats.json";
            if (File.Exists(result_file)) File.Delete(result_file);
            File.WriteAllText(result_file, json);
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
        }
    }
}
