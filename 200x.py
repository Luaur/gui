import discord
from discord.ext import commands, tasks
import subprocess
import os
import asyncio
import sys

# --- KONFIGURASI ---
BOT_TOKEN = "MzzTQ3MTU2NTczNDkzNjA1MTg2Ng.GqAQHt.kANo3Y30NLSvdXvh9fJfYdwWmcJa7-c_ZnxPhM"
OWNER_ID = 1463723091489194150
ROBLOX_PKG = "com.roblox.client"
SS_PATH = "/data/data/com.termux/files/home/ss.png"
VIP_SERVER_LINK = "MASUKKAN_LINK_PRIVATE_SERVER_ANDA_DI_SINI"

auto_recovery = False

# --- SETUP BOT ---
class MyBot(commands.Bot):
    def __init__(self):
        super().__init__(command_prefix="!", intents=discord.Intents.default())

    async def setup_hook(self):
        self.loop.create_task(auto_recovery_loop())
        await self.tree.sync()

bot = MyBot()

# --- FUNGSI PEMBANTU ---
def exec_cmd(cmd):
    try:
        result = subprocess.check_output(cmd, shell=True, stderr=subprocess.STDOUT, text=True)
        return result.strip() if result else "Tidak diketahui"
    except subprocess.CalledProcessError:
        return "Gagal membaca"

def is_roblox_running():
    return exec_cmd(f"su -c pidof {ROBLOX_PKG} > /dev/null 2>&1 && echo 1 || echo 0") == "1"

def get_detailed_status():
    status = "=== STATUS SISTEM TERMUX ===\n\n"
    
    status += "[ INFORMASI SOFTWARE ]\n"
    status += f"Model Perangkat : {exec_cmd('getprop ro.product.model')}\n"
    status += f"Versi Android   : {exec_cmd('getprop ro.build.version.release')} (API {exec_cmd('getprop ro.build.version.sdk')})\n"
    status += f"Versi Kernel    : {exec_cmd('uname -r')}\n"
    status += f"Uptime Sistem   : {exec_cmd('uptime -p')}\n\n"

    status += "[ INFORMASI HARDWARE ]\n"
    status += f"Penyimpanan     : {exec_cmd('''df -h /data | awk 'NR==2 {print $3\" / \"$2\" (\"$5\" Terpakai)\"}'''')}\n"
    status += f"RAM             : {exec_cmd('''free -m | awk '/Mem:/ {print $3\" MB / \"$2\" MB\"}'''')}\n"
    
    temp = exec_cmd("su -c cat /sys/class/thermal/thermal_zone0/temp")
    status += f"Suhu Perangkat  : {int(temp)//1000} C\n" if temp.isdigit() else "Suhu Perangkat  : Gagal membaca\n"
    
    status += f"Baterai         : {exec_cmd('''su -c dumpsys battery | grep level | awk '{print $2}'''')}%\n"
    status += f"IP WiFi (wlan0) : {exec_cmd('''ifconfig wlan0 | grep 'inet ' | awk '{print $2}'''')}\n"

    return status

# --- UI TOMBOL (PANEL) ---
class PanelView(discord.ui.View):
    def __init__(self):
        super().__init__(timeout=None)

    async def interaction_check(self, interaction: discord.Interaction) -> bool:
        if interaction.user.id != OWNER_ID:
            await interaction.response.send_message("Akses Ditolak.", ephemeral=True)
            return False
        return True

    async def update_panel(self, interaction: discord.Interaction, message_text: str, file=None):
        # Hapus pesan lama, kirim yang baru di bawah
        await interaction.message.delete()
        if file:
            await interaction.channel.send(content=message_text, view=PanelView(), file=file)
        else:
            await interaction.channel.send(content=message_text, view=PanelView())

    @discord.ui.button(label="Join VIP", style=discord.ButtonStyle.success, custom_id="btn_vip")
    async def btn_vip(self, interaction: discord.Interaction, button: discord.ui.Button):
        os.system(f"su -c am start -a android.intent.action.VIEW -d \"{VIP_SERVER_LINK}\" > /dev/null 2>&1")
        await self.update_panel(interaction, "Status: Mencoba menghubungkan ke Private Server...")

    @discord.ui.button(label="Stop", style=discord.ButtonStyle.danger, custom_id="btn_stop")
    async def btn_stop(self, interaction: discord.Interaction, button: discord.ui.Button):
        global auto_recovery
        auto_recovery = False
        os.system(f"su -c am force-stop {ROBLOX_PKG}")
        await self.update_panel(interaction, "Status: Roblox di-force stop dan Auto-Recovery dimatikan.")

    @discord.ui.button(label="Screenshot", style=discord.ButtonStyle.primary, custom_id="btn_ss")
    async def btn_ss(self, interaction: discord.Interaction, button: discord.ui.Button):
        await interaction.response.defer() # Mencegah timeout saat mengambil SS
        os.system(f"su -c screencap -p {SS_PATH}")
        file = discord.File(SS_PATH, filename="screenshot.png")
        await interaction.message.delete()
        await interaction.channel.send(content="Status: Tangkapan layar berhasil diambil.", view=PanelView(), file=file)

    @discord.ui.button(label="Cek Hardware", style=discord.ButtonStyle.secondary, custom_id="btn_hw", row=1)
    async def btn_hw(self, interaction: discord.Interaction, button: discord.ui.Button):
        status = get_detailed_status()
        formatted_status = f"```ini\n{status}\n```"
        await self.update_panel(interaction, formatted_status)

    @discord.ui.button(label="Toggle Recovery", style=discord.ButtonStyle.secondary, custom_id="btn_rec", row=1)
    async def btn_rec(self, interaction: discord.Interaction, button: discord.ui.Button):
        global auto_recovery
        auto_recovery = not auto_recovery
        state = "AKTIF" if auto_recovery else "NONAKTIF"
        await self.update_panel(interaction, f"Status Auto-Recovery: {state}")

# --- COMMANDS ---
@bot.tree.command(name="panel", description="Munculkan panel kontrol UI")
async def panel(interaction: discord.Interaction):
    if interaction.user.id != OWNER_ID:
        await interaction.response.send_message("Akses Ditolak.", ephemeral=True)
        return
    await interaction.response.send_message("Kontrol Panel Roblox Termux", view=PanelView())

@bot.tree.command(name="update", description="Update script bot via lampiran")
async def update(interaction: discord.Interaction, file: discord.Attachment):
    if interaction.user.id != OWNER_ID:
        await interaction.response.send_message("Akses Ditolak.", ephemeral=True)
        return
    
    if not file.filename.endswith(".py"):
        await interaction.response.send_message("Pembaruan gagal. Harap lampirkan file berekstensi .py")
        return

    await interaction.response.send_message("Mengunduh skrip baru dan merestart bot...")
    await file.save("bot.py")
    
    # Restart script Python secara otomatis
    os.execv(sys.executable, ['python'] + sys.argv)

# --- AUTO RECOVERY LOOP ---
async def auto_recovery_loop():
    await bot.wait_until_ready()
    while not bot.is_closed():
        if auto_recovery and not is_roblox_running():
            print("[Auto-Recovery] Roblox mati, menyambungkan kembali ke VIP Server...")
            os.system(f"su -c am start -a android.intent.action.VIEW -d \"{VIP_SERVER_LINK}\" > /dev/null 2>&1")
        await asyncio.sleep(20)

@bot.event
async def on_ready():
    print(f"Bot berhasil login sebagai {bot.user}")

bot.run(BOT_TOKEN)
