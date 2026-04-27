import discord
from discord.ext import commands, tasks
from discord.app_commands import checks, AppCommandError
import subprocess
import os
import asyncio
import sys
import traceback
import io

# --- KONFIGURASI ---
# PERINGATAN: Segera ganti token ini di Discord Developer Portal jika sudah terekspos!
BOT_TOKEN = "MTQzz3MTU2NTczNDkzNjA1MTg2Ng.GqAQHt.kANo3Y30NLSvdXvh9fJfYdwWmcJa7-c_ZnxPhM"
OWNER_ID = 1463723091489194150
PANEL_CHANNEL_ID = 1490785488704114780  # GANTI DENGAN ID CHANNEL DISCORD ANDA
ROBLOX_PKG = "com.roblox.client"
VIP_SERVER_LINK = "MASUKKAN_LINK_PRIVATE_SERVER_ANDA_DI_SINI"

auto_recovery_enabled = False

class TermuxBot(commands.Bot):
    def __init__(self):
        intents = discord.Intents.default()
        intents.message_content = True
        intents.members = True
        super().__init__(command_prefix="!", intents=intents)

    async def setup_hook(self):
        # Memulai background task untuk recovery
        self.loop.create_task(auto_recovery_task())
        try:
            await self.tree.sync()
        except Exception as e:
            print(f"Gagal sync command tree: {e}")

bot = TermuxBot()

# --- FUNGSI SISTEM (SHELL) ---

def run_shell(cmd, timeout_sec=10):
    """Menjalankan perintah shell dan mengembalikan output teks."""
    try:
        res = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=timeout_sec)
        if res.returncode == 0 and res.stdout.strip():
            return res.stdout.strip()
        return "Tidak tersedia"
    except Exception:
        return "Error"

def run_shell_bytes(cmd, timeout_sec=15):
    """Menjalankan perintah shell dan mengembalikan output mentah (bytes)."""
    try:
        res = subprocess.run(cmd, shell=True, capture_output=True, timeout=timeout_sec)
        if res.returncode == 0 and res.stdout:
            return res.stdout
        return None
    except Exception:
        return None

def is_roblox_alive():
    """Mengecek apakah proses Roblox sedang berjalan."""
    res = run_shell(f"su -c pidof {ROBLOX_PKG}")
    return "Tidak tersedia" not in res and "Error" not in res

def launch_roblox_vip():
    """Membuka Roblox langsung melalui Link VIP."""
    return run_shell(f"su -c am start -a android.intent.action.VIEW -d \"{VIP_SERVER_LINK}\"")

def create_embed(title, description, color=discord.Color.blue()):
    embed = discord.Embed(title=title, description=description, color=color)
    embed.set_footer(text="Termux Root Manager | System Verified")
    return embed

def get_system_stats():
    """Mengambil data hardware perangkat."""
    model = run_shell('getprop ro.product.model')
    uptime = run_shell('uptime -p')
    ram = run_shell('''free -m | awk '/Mem:/ {print $3" MB / "$2" MB"}' ''')
    bat = run_shell('''su -c dumpsys battery | grep level | awk '{print $2}' ''')
    temp_cpu = run_shell("su -c cat /sys/class/thermal/thermal_zone0/temp")
    
    suhu = f"{int(temp_cpu)//1000} C" if temp_cpu.isdigit() else "Error"

    embed = discord.Embed(title="Status Perangkat", color=discord.Color.dark_grey())
    embed.add_field(name="Hardware", value=f"**Model:** {model}\n**Uptime:** {uptime}", inline=False)
    embed.add_field(name="Resource", value=f"**RAM:** {ram}\n**Suhu:** {suhu}\n**Baterai:** {bat}%", inline=False)
    return embed

# --- INTERFACE PANEL ---

class ControlPanel(discord.ui.View):
    def __init__(self):
        super().__init__(timeout=None)

    async def interaction_check(self, interaction: discord.Interaction) -> bool:
        if interaction.user.id != OWNER_ID:
            await interaction.response.send_message("Akses Ditolak.", ephemeral=True)
            return False
        return True

    async def update_view(self, interaction: discord.Interaction, embed: discord.Embed, file=None):
        try:
            if file:
                # Jika ada file (screenshot), hapus pesan lama dan kirim baru agar gambar muncul
                await interaction.message.delete()
                await interaction.channel.send(embed=embed, view=ControlPanel(), file=file)
            else:
                # Jika hanya teks/status, edit pesan yang ada agar lebih smooth
                await interaction.response.edit_message(embed=embed, view=self)
        except:
            await interaction.channel.send(embed=embed, view=ControlPanel())

    @discord.ui.button(label="Start VIP", style=discord.ButtonStyle.success, row=0)
    async def btn_start(self, interaction: discord.Interaction, button: discord.ui.Button):
        launch_roblox_vip()
        await self.update_view(interaction, create_embed("Sistem Start", "Membuka Roblox via VIP Link...", discord.Color.green()))

    @discord.ui.button(label="Stop", style=discord.ButtonStyle.danger, row=0)
    async def btn_stop(self, interaction: discord.Interaction, button: discord.ui.Button):
        global auto_recovery_enabled
        auto_recovery_enabled = False
        run_shell(f"su -c am force-stop {ROBLOX_PKG}")
        await self.update_view(interaction, create_embed("Sistem Stop", "Roblox ditutup. Recovery dinonaktifkan.", discord.Color.red()))

    @discord.ui.button(label="Clear Cache", style=discord.ButtonStyle.danger, row=0)
    async def btn_cache(self, interaction: discord.Interaction, button: discord.ui.Button):
        run_shell(f"su -c pm clear {ROBLOX_PKG}")
        await self.update_view(interaction, create_embed("Data Reset", "Cache dan data Roblox dibersihkan.", discord.Color.orange()))

    @discord.ui.button(label="Screenshot", style=discord.ButtonStyle.primary, row=1)
    async def btn_ss(self, interaction: discord.Interaction, button: discord.ui.Button):
        await interaction.response.defer() 
        # Mengambil data gambar langsung ke RAM
        image_bytes = run_shell_bytes("su -c screencap -p")
        
        if image_bytes:
            image_stream = io.BytesIO(image_bytes)
            file = discord.File(image_stream, filename="screenshot.png")
            embed = create_embed("Live Screen", "Tampilan layar saat ini:", discord.Color.blue())
            embed.set_image(url="attachment://screenshot.png")
            await self.update_view(interaction, embed, file=file)
        else:
            await interaction.followup.send("Gagal mengambil gambar.", ephemeral=True)

    @discord.ui.button(label="Info Alat", style=discord.ButtonStyle.secondary, row=1)
    async def btn_hw(self, interaction: discord.Interaction, button: discord.ui.Button):
        await self.update_view(interaction, get_system_stats())

    @discord.ui.button(label="Recovery", style=discord.ButtonStyle.secondary, row=1)
    async def btn_rec(self, interaction: discord.Interaction, button: discord.ui.Button):
        global auto_recovery_enabled
        auto_recovery_enabled = not auto_recovery_enabled
        state = "AKTIF" if auto_recovery_enabled else "NONAKTIF"
        color = discord.Color.gold() if auto_recovery_enabled else discord.Color.light_grey()
        await self.update_view(interaction, create_embed("Auto Recovery", f"Status: **{state}**", color))

    @discord.ui.button(label="Power", style=discord.ButtonStyle.secondary, row=2)
    async def btn_pwr(self, interaction: discord.Interaction, button: discord.ui.Button):
        run_shell("su -c input keyevent 26")
        await interaction.response.send_message("Power Toggled.", ephemeral=True)

    @discord.ui.button(label="Reboot HP", style=discord.ButtonStyle.danger, row=2)
    async def btn_reboot(self, interaction: discord.Interaction, button: discord.ui.Button):
        await interaction.response.send_message("Rebooting device...")
        run_shell("su -c reboot")

# --- LOGIKA OTOMATIS ---

async def auto_recovery_task():
    """Memastikan Roblox tetap hidup jika fitur recovery aktif."""
    await bot.wait_until_ready()
    while not bot.is_closed():
        try:
            if auto_recovery_enabled and not is_roblox_alive():
                print("Recovery: Roblox mati, mencoba masuk VIP...")
                launch_roblox_vip()
        except:
            pass
        await asyncio.sleep(25) # Cek setiap 25 detik

@bot.event
async def on_ready():
    print(f"Terhubung sebagai: {bot.user}")
    channel = bot.get_channel(PANEL_CHANNEL_ID)
    if channel:
        # Menghapus jejak panel lama agar rapi
        async for message in channel.history(limit=15):
            if message.author == bot.user:
                try: await message.delete()
                except: pass
        
        await channel.send(
            embed=create_embed("Panel Kontrol Online", "Sistem siap digunakan. Gunakan tombol di bawah."), 
            view=ControlPanel()
        )

# --- COMMANDS ---

@bot.tree.command(name="update", description="Update script dengan mengunggah file .py baru")
async def update_cmd(interaction: discord.Interaction, file: discord.Attachment):
    if interaction.user.id != OWNER_ID:
        await interaction.response.send_message("Akses Ditolak.", ephemeral=True)
        return
    
    if not file.filename.endswith('.py'):
        await interaction.response.send_message("Hanya file .py yang diterima.", ephemeral=True)
        return

    await interaction.response.send_message("Memperbarui sistem dan me-restart bot...")
    
    # Simpan file baru menimpa script yang sedang jalan
    script_path = os.path.abspath(sys.argv[0])
    await file.save(script_path)
    
    # Restart bot secara otomatis
    os.execv(sys.executable, ['python'] + sys.argv)

if __name__ == "__main__":
    bot.run(BOT_TOKEN)
