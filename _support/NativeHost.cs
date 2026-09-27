using System;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Web.Script.Serialization;
using System.Collections.Generic;

public class DimomuleNativeHost
{
    const int MaxMessageBytes = 1024 * 1024;
    const string AllowedOrigin = "chrome-extension://mihhpbnljinclnfipcadonlnnnnngkbk/";
    static readonly string LogPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "Dimomule.log");

    static void Log(string s)
    {
        try { File.AppendAllText(LogPath, DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fff") + " " + s + Environment.NewLine, Encoding.UTF8); } catch { }
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
            if (String.IsNullOrEmpty(url) || !url.StartsWith("ed2k://", StringComparison.OrdinalIgnoreCase) || url.Length > 32768 || url.IndexOf('\r') >= 0 || url.IndexOf('\n') >= 0 || url.IndexOf('\0') >= 0)
            { Log("REJECT invalid url"); Send(new {ok=false,error="invalid_ed2k_url"}); return 6; }

            Process.Start(new ProcessStartInfo { FileName=url, UseShellExecute=true });
            Log("OPEN_OK"); Send(new {ok=true}); return 0;
        }
        catch (Exception ex)
        { Log("EXCEPTION " + ex.GetType().FullName + ": " + ex.Message); try { Send(new {ok=false,error=ex.Message}); } catch { } return 10; }
    }
}
