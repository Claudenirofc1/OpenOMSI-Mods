// "Instalar OpenOMSI HOF-Auto.exe": a window-less starter for the Mod Manager (no black console).
// It only starts Instalar-HOF-Auto.ps1, which sits beside it, with its own window (message
// boxes and forms). Built by the workflow with the csc that Windows brings (.NET Framework 4).
using System;
using System.Diagnostics;
using System.IO;
using System.Windows.Forms;

static class Instalar
{
    [STAThread]
    static int Main(string[] args)
    {
        string here = AppDomain.CurrentDomain.BaseDirectory;
        string ps1 = Path.Combine(here, "Instalar-HOF-Auto.ps1");
        if (!File.Exists(ps1) || here.IndexOf("\\Temp\\", StringComparison.OrdinalIgnoreCase) >= 0)
        {
            MessageBox.Show("Extraia o ZIP inteiro para uma pasta (botao direito > Extrair tudo) e abra este programa de dentro dela.\n\nNao abra direto de dentro do ZIP.", "OpenOMSI Mod Manager", MessageBoxButtons.OK, MessageBoxIcon.Information);
            return 2;
        }
        string modo = args.Length > 0 && args[0].Length > 0 ? args[0] : "Menu";
        var psi = new ProcessStartInfo("powershell.exe", "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File \"" + ps1 + "\" -Modo " + modo)
        {
            WorkingDirectory = here,
            UseShellExecute = false,
            CreateNoWindow = true,
        };
        try
        {
            using (var p = Process.Start(psi)) { p.WaitForExit(); return p.ExitCode; }
        }
        catch (Exception e)
        {
            MessageBox.Show("Nao foi possivel iniciar o gerenciador: " + e.Message, "OpenOMSI Mod Manager", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return 1;
        }
    }
}
