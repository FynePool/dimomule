using System;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Web.Script.Serialization;
using System.Collections.Generic;
using System.Text.RegularExpressions;

public class DimomuleNativeHost
{
    const int MaxMessageBytes = 1024 * 1024;
    const string AllowedOrigin = "chrome-extension://jipokengmllmldjhfjceeemnnnjeicli/";
    // Formato eD2K ammesso: file, server, serverlist. Stesso pattern di Chrome/service-worker.js.
    const string Ed2kPattern = @"^[Ee][Dd]2[Kk]://\|(?:file\|[^|\x00-\x1f\x22\x7f]+\|[1-9][0-9]{0,15}\|[0-9A-Fa-f]{32}\|(?:(?:h=[A-Za-z2-7]{32}|p=[0-9A-Fa-f]{32}(?::[0-9A-Fa-f]{32})*|s=https?://[^|\x00-\x20\x22\x7f]+)\|)*/(?:\|sources(?:,[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)*:[0-9]{1,5})+\|/)?|server\|[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)*\|[0-9]{1,5}\|/|serverlist\|https?://[^|\x00-\x20\x22\x7f]+\|/)$";
    static readonly Regex Ed2kRegex = new Regex(Ed2kPattern);
    static readonly string LogPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "Dimomule.log");

    static void Log(string s)
    {
        try { File.AppendAllText(LogPath, DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fff") + " " + s + Environment.NewLine, Encoding.UTF8); } catch { }
    }

    static bool ValidEd2k(string s)
    {
        if (String.IsNullOrEmpty(s) || s.Length > 32768) return false;
        foreach (char c in s) { if (c < 0x20 || c == 0x7f || c == '"') return false; }
        return Ed2kRegex.IsMatch(s);
    }

    static byte[] ReadExact(Stream input, int count)
    {
        byte[] data = new byte[count]; int offset = 0;
        while (offset < count) { int n = input.Read(data, offset, count-offset); if (n <= 0) return null; offset += n; }
        return data;
    }

    static void Send(object obj)
    {
        var js = new JavaScriptSerializer();
        byte[] payload = Encoding.UTF8.GetBytes(js.Serialize(obj));
        byte[] len = BitConverter.GetBytes(payload.Length);
        Stream output = Console.OpenStandardOutput();
        output.Write(len,0,len.Length); output.Write(payload,0,payload.Length); output.Flush();
    }

    public static int Main(string[] args)
    {
        try
        {
            string origin = (args != null && args.Length > 0) ? args[0] : "";
            if (!String.Equals(origin, AllowedOrigin, StringComparison.OrdinalIgnoreCase))
            { Log("REJECT origin=" + origin); Send(new {ok=false,error="unauthorized_origin"}); return 2; }

            Stream input = Console.OpenStandardInput();
            byte[] lenBytes = ReadExact(input,4); if (lenBytes == null) return 3;
            int length = BitConverter.ToInt32(lenBytes,0);
            if (length <= 0 || length > MaxMessageBytes) { Send(new {ok=false,error="bad_message_length"}); return 4; }
            byte[] payload = ReadExact(input,length); if (payload == null) { Send(new {ok=false,error="incomplete_message"}); return 5; }

            var js = new JavaScriptSerializer();
            var data = js.DeserializeObject(Encoding.UTF8.GetString(payload)) as Dictionary<string,object>;
            string url = (data != null && data.ContainsKey("url") && data["url"] != null) ? data["url"].ToString().Trim() : null;
            if (!ValidEd2k(url))
            { Log("REJECT invalid url"); Send(new {ok=false,error="invalid_ed2k_url"}); return 6; }

            Process.Start(new ProcessStartInfo { FileName=url, UseShellExecute=true });
            Log("OPEN_OK"); Send(new {ok=true}); return 0;
        }
        catch (Exception ex)
        { Log("EXCEPTION " + ex.GetType().FullName + ": " + ex.Message); try { Send(new {ok=false,error=ex.Message}); } catch { } return 10; }
    }
}
