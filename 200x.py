import discord
from discord.ext import commands, tasks
from discord.app_commands import checks, AppCommandError
import subprocess
import os
import asyncio
import sys
import traceback
from datetime import timedelta

BOT_TOKEN = "MTQzz3MTU2NTczNDkzNjA1MTg2Ng.GqAQHt.kANo3Y30NLSvdXvh9fJfYdwWmcJa7-c_ZnxPhM"
OWNER_ID = 1463723091489194150
ROBLOX_PKG = "com.roblox.client"
SS_PATH = "/data/data/com.termux/files/home/ss.png"
VIP_SERVER_LINK = "MASUKKAN_LINK_PRIVATE_SERVER_ANDA_DI_SINI"

auto_recovery_enabled = False

class TermuxBot(commands.Bot):
    def __init__(self):
        intents = discord.Intents.default()
        intents.message_content = True
        intents.members = True
        super().__init__(command_prefix="!", intents=intents)

    async def setup_hook(self):
        self.loop.create_task(auto_recovery_task())
        try:
            await self.tree.sync()
        except:
            pass

    async def on_error(self, event_method: str, /, *args, **kwargs):
        traceback.print_exc()

bot = TermuxBot()

@bot.tree.error
async def on_app_command_error(interaction: discord.Interaction, error: AppCommandError):
    err_msg = f"Terjadi kesalahan: `{error}`"
    if isinstance(error, checks.MissingPermissions):
        err_msg = "Akses Ditolak: Anda tidak memiliki izin."
    try:
        if not interaction.response.is_done():
            await interaction.response.send_message(err_msg, ephemeral=True)
        else:
            await interaction.followup.send(err_msg, ephemeral=True)
    except:
        pass

def run_shell(cmd, timeout_sec=10):
    try:
        res = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=timeout_sec)
        if res.returncode == 0 and res.stdout.strip():
            return res.stdout.strip()
        return "Tidak tersedia"
    except subprocess.TimeoutExpired:
        return "Timeout"
    except Exception:
        return "Error"

def is_roblox_alive():
    res = run_shell(f"su -c pidof {ROBLOX_PKG}")
    return "Tidak tersedia" not in res and "Error" not in res and "Timeout" not in res

def create_embed(title, description, color=discord.Color.blue()):
    embed = discord.Embed(title=title, description=description, color=color)
    embed.set_footer(text="Termux Root System Manager")
    return embed

def get_system_stats():
    model = run_shell('getprop ro.product.model')
    android = run_shell('getprop ro.build.version.release')
    uptime = run_shell('uptime -p')
    disk = run_shell('''df -h /data | awk 'NR==2 {print $3" / "$2" ("$5" Terpakai)"}' ''')
    ram = run_shell('''free -m | awk '/Mem:/ {print $3" MB / "$2" MB"}' ''')
    ip = run_shell('''ifconfig wlan0 | grep 'inet ' | awk '{print $2}' ''')
    bat = run_shell('''su -c dumpsys battery | grep level | awk '{print $2}' ''')
    temp_cpu = run_shell("su -c cat /sys/class/thermal/thermal_zone0/temp")
    
    suhu = f"{int(temp_cpu)//1000} C" if temp_cpu.isdigit() else "Error"

    embed = discord.Embed(title="Status Perangkat", color=discord.Color.dark_grey())
    embed.add_field(name="Sistem", value=f"**Model:** {model}\n**Android:** {android}\n**Uptime:** {uptime}", inline=False)
    embed.add_field(name="Sumber Daya", value=f"**RAM:** {ram}\n**Disk:** {disk}\n**Suhu:** {suhu}\n**Baterai:** {bat}%", inline=False)
    embed.add_field(name="Network", value=f"**IP:** {ip}", inline=False)
    return embed

class ControlPanel(discord.ui.View):
    def __init__(self):
        super().__init__(timeout=None)

    async def interaction_check(self, interaction: discord.Interaction) -> bool:
        if interaction.user.id != OWNER_ID:
            await interaction.response.send_message("Hanya owner yang dapat mengakses panel.", ephemeral=True)
            return False
        return True

    async def update_view(self, interaction: discord.Interaction, embed: discord.Embed, file=None):
        try:
            await interaction.message.delete()
        except:
            pass 
        if file:
            await interaction.channel.send(embed=embed, view=ControlPanel(), file=file)
        else:
            await interaction.channel.send(embed=embed, view=ControlPanel())

    @discord.ui.button(label="Start", style=discord.ButtonStyle.success, row=0)
    async def btn_start(self, interaction: discord.Interaction, button: discord.ui.Button):
        run_shell(f"su -c monkey -p {ROBLOX_PKG} -c android.intent.category.LAUNCHER 1")
        await self.update_view(interaction, create_embed("Aplikasi Dimulai", "Membuka Roblox...", discord.Color.green()))

    @discord.ui.button(label="Join VIP", style=discord.ButtonStyle.success, row=0)
    async def btn_vip(self, interaction: discord.Interaction, button: discord.ui.Button):
        run_shell(f"su -c am start -a android.intent.action.VIEW -d \"{VIP_SERVER_LINK}\"")
        await self.update_view(interaction, create_embed("VIP Join", "Masuk melalui link Private Server...", discord.Color.green()))

    @discord.ui.button(label="Stop", style=discord.ButtonStyle.danger, row=0)
    async def btn_stop(self, interaction: discord.Interaction, button: discord.ui.Button):
        global auto_recovery_enabled
        auto_recovery_enabled = False
        run_shell(f"su -c am force-stop {ROBLOX_PKG}")
        await self.update_view(interaction, create_embed("Roblox Berhenti", "Aplikasi ditutup paksa. Recovery dinonaktifkan.", discord.Color.red()))

    @discord.ui.button(label="Clear Cache", style=discord.ButtonStyle.danger, row=0)
    async def btn_cache(self, interaction: discord.Interaction, button: discord.ui.Button):
        run_shell(f"su -c pm clear {ROBLOX_PKG}")
        await self.update_view(interaction, create_embed("Data Dihapus", "Cache dan data Roblox berhasil dibersihkan.", discord.Color.orange()))

    @discord.ui.button(label="Screenshot", style=discord.ButtonStyle.primary, row=1)
    async def btn_ss(self, interaction: discord.Interaction, button: discord.ui.Button):
        await interaction.response.defer() 
        run_shell(f"su -c screencap -p {SS_PATH}")
        if os.path.exists(SS_PATH) and os.path.getsize(SS_PATH) > 0:
            file = discord.File(SS_PATH, filename="screenshot.png")
            embed = create_embed("Screenshot", "Tampilan layar perangkat saat ini:", discord.Color.blue())
            embed.set_image(url="attachment://screenshot.png")
            await interaction.message.delete()
            await interaction.channel.send(embed=embed, view=ControlPanel(), file=file)
        else:
            await self.update_view(interaction, create_embed("Gagal", "Tidak dapat mengambil screenshot.", discord.Color.red()))

    @discord.ui.button(label="Info Sistem", style=discord.ButtonStyle.secondary, row=1)
    async def btn_hw(self, interaction: discord.Interaction, button: discord.ui.Button):
        await self.update_view(interaction, get_system_stats())

    @discord.ui.button(label="Recovery", style=discord.ButtonStyle.secondary, row=1)
    async def btn_rec(self, interaction: discord.Interaction, button: discord.ui.Button):
        global auto_recovery_enabled
        auto_recovery_enabled = not auto_recovery_enabled
        state = "AKTIF" if auto_recovery_enabled else "NONAKTIF"
        await self.update_view(interaction, create_embed("Auto Recovery", f"Status saat ini: **{state}**", discord.Color.gold()))

    @discord.ui.button(label="Logs", style=discord.ButtonStyle.primary, row=1)
    async def btn_log(self, interaction: discord.Interaction, button: discord.ui.Button):
        logs = run_shell(f"su -c logcat -d | grep {ROBLOX_PKG} | tail -n 10")
        embed = create_embed("System Logs", f"```\n{logs}\n```", discord.Color.light_grey())
        await self.update_view(interaction, embed)

    @discord.ui.button(label="Lock/Wake", style=discord.ButtonStyle.secondary, row=2)
    async def btn_pwr(self, interaction: discord.Interaction, button: discord.ui.Button):
        run_shell("su -c input keyevent 26")
        await self.update_view(interaction, create_embed("Power Toggle", "Layar dinyalakan/dimatikan.", discord.Color.blue()))

    @discord.ui.button(label="Reboot", style=discord.ButtonStyle.danger, row=2)
    async def btn_reboot(self, interaction: discord.Interaction, button: discord.ui.Button):
        run_shell("su -c reboot")
        await self.update_view(interaction, create_embed("Reboot", "Perangkat sedang memulai ulang...", discord.Color.dark_red()))

@bot.tree.command(name="panel", description="Buka panel kontrol utama")
async def panel_cmd(interaction: discord.Interaction):
    if interaction.user.id != OWNER_ID:
        await interaction.response.send_message("Akses Ditolak.", ephemeral=True)
        return
    await interaction.response.send_message(embed=create_embed("Panel Kontrol", "Gunakan tombol di bawah untuk mengelola perangkat."), view=ControlPanel())

@bot.tree.command(name="update", description="Pembaruan script otomatis")
async def update_cmd(interaction: discord.Interaction, file: discord.Attachment):
    if interaction.user.id != OWNER_ID:
        await interaction.response.send_message("Akses Ditolak.", ephemeral=True)
        return
    await interaction.response.send_message("Mengunduh update...")
    script_name = sys.argv[0]
    await file.save(script_name)
    os.execv(sys.executable, ['python', script_name])

@bot.tree.command(name="ping", description="Cek latensi")
async def ping_cmd(interaction: discord.Interaction):
    await interaction.response.send_message(f"Latensi: {round(bot.latency * 1000)}ms")

@bot.tree.command(name="clear", description="Hapus pesan")
@checks.has_permissions(manage_messages=True)
async def clear_cmd(interaction: discord.Interaction, jumlah: int):
    await interaction.response.defer(ephemeral=True)
    await interaction.channel.purge(limit=jumlah)
    await interaction.followup.send(f"Berhasil menghapus {jumlah} pesan.")

@bot.tree.command(name="kick", description="Keluarkan member")
@checks.has_permissions(kick_members=True)
async def kick_cmd(interaction: discord.Interaction, member: discord.Member, alasan: str = "Tidak ada"):
    await member.kick(reason=alasan)
    await interaction.response.send_message(f"{member.mention} dikeluarkan.")

@bot.tree.command(name="ban", description="Blokir member")
@checks.has_permissions(ban_members=True)
async def ban_cmd(interaction: discord.Interaction, member: discord.Member, alasan: str = "Tidak ada"):
    await member.ban(reason=alasan)
    await interaction.response.send_message(f"{member.mention} diblokir.")

async def auto_recovery_task():
    await bot.wait_until_ready()
    while not bot.is_closed():
        try:
            if auto_recovery_enabled and not is_roblox_alive():
                run_shell(f"su -c am start -a android.intent.action.VIEW -d \"{VIP_SERVER_LINK}\"")
        except:
            pass
        await asyncio.sleep(20)

@bot.event
async def on_ready():
    print(f"Login: {bot.user}")

if __name__ == "__main__":
    bot.run(BOT_TOKEN)
