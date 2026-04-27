#include <dpp/dpp.h>
#include <iostream>
#include <string>
#include <vector>
#include <thread>
#include <chrono>
#include <cstdlib>
#include <cstdio>

const std::string BOT_TOKEN = "MTQ3MTU2NzzczNDkzNjA1MTg2Ng.GqAQHt.kANo3Y30NLSvdXvh9fJfYdwWmcJa7-c_ZnxPhM";
const uint64_t OWNER_ID = 1463723091489194150; 
const std::string ROBLOX_PKG = "com.roblox.client";
const std::string SS_PATH = "/data/data/com.termux/files/home/ss.png";

// Masukkan link private server Anda di sini
const std::string VIP_SERVER_LINK = "MASUKKAN_LINK_PRIVATE_SERVER_ANDA_DI_SINI";

bool auto_recovery = false;

// --- FUNGSI PEMBANTU ---

std::string ExecCmd(const std::string& cmd) {
    std::string result = "";
    char buffer[128];
    FILE* pipe = popen(cmd.c_str(), "r");
    if (!pipe) return "Gagal membaca";
    while (fgets(buffer, sizeof(buffer), pipe) != NULL) {
        result += buffer;
    }
    pclose(pipe);
    
    if (!result.empty() && result.back() == '\n') {
        result.pop_back();
    }
    return result.empty() ? "Tidak diketahui" : result;
}

// --- FUNGSI SISTEM TERMUX ROOT ---

bool IsRobloxRunning() {
    std::string cmd = "su -c pidof " + ROBLOX_PKG + " > /dev/null 2>&1";
    return (system(cmd.c_str()) == 0);
}

void TakeScreenshot() {
    std::string cmd = "su -c screencap -p " + SS_PATH;
    system(cmd.c_str());
}

std::string GetDetailedStatus() {
    std::string result = "=== STATUS SISTEM TERMUX ===\n\n";

    result += "[ INFORMASI SOFTWARE ]\n";
    result += "Model Perangkat : " + ExecCmd("getprop ro.product.model") + "\n";
    result += "Versi Android   : " + ExecCmd("getprop ro.build.version.release") + " (API " + ExecCmd("getprop ro.build.version.sdk") + ")\n";
    result += "Versi Kernel    : " + ExecCmd("uname -r") + "\n";
    result += "Uptime Sistem   : " + ExecCmd("uptime -p") + "\n\n";

    result += "[ INFORMASI HARDWARE ]\n";
    result += "Penyimpanan     : " + ExecCmd("df -h /data | awk 'NR==2 {print $3\" / \"$2\" (\"$5\" Terpakai)\"}'") + "\n";
    result += "RAM             : " + ExecCmd("free -m | awk '/Mem:/ {print $3\" MB / \"$2\" MB\"}'") + "\n";
    
    std::string tempStr = ExecCmd("su -c cat /sys/class/thermal/thermal_zone0/temp");
    try {
        int temp = std::stoi(tempStr) / 1000;
        result += "Suhu Perangkat  : " + std::to_string(temp) + " C\n";
    } catch (...) {
        result += "Suhu Perangkat  : Gagal membaca sensor\n";
    }

    result += "Baterai         : " + ExecCmd("su -c dumpsys battery | grep level | awk '{print $2}'") + "%\n";
    
    std::string batTempStr = ExecCmd("su -c dumpsys battery | grep temperature | awk '{print $2}'");
    try {
        float batTemp = std::stof(batTempStr) / 10.0f;
        char batBuf[20];
        snprintf(batBuf, sizeof(batBuf), "%.1f", batTemp);
        result += "Suhu Baterai    : " + std::string(batBuf) + " C\n";
    } catch (...) {}

    result += "IP WiFi (wlan0) : " + ExecCmd("ifconfig wlan0 | grep 'inet ' | awk '{print $2}'") + "\n";

    return result;
}

// --- FUNGSI PEMBUAT PANEL TOMBOL ---

dpp::message CreatePanelMessage(const std::string& text) {
    dpp::message msg(text);
    
    // Baris Pertama
    msg.add_component(
        dpp::component().add_component(
            dpp::component().set_type(dpp::cot_button).set_style(dpp::cos_success).set_label("Start").set_id("btn_start")
        ).add_component(
            dpp::component().set_type(dpp::cot_button).set_style(dpp::cos_success).set_label("Join VIP").set_id("btn_vip")
        ).add_component(
            dpp::component().set_type(dpp::cot_button).set_style(dpp::cos_danger).set_label("Stop").set_id("btn_stop")
        )
    );
    
    // Baris Kedua
    msg.add_component(
        dpp::component().add_component(
            dpp::component().set_type(dpp::cot_button).set_style(dpp::cos_primary).set_label("Screenshot").set_id("btn_ss")
        ).add_component(
            dpp::component().set_type(dpp::cot_button).set_style(dpp::cos_secondary).set_label("Cek Hardware").set_id("btn_hw")
        ).add_component(
            dpp::component().set_type(dpp::cot_button).set_style(dpp::cos_secondary).set_label("Toggle Recovery").set_id("btn_rec")
        )
    );
    return msg;
}

// --- FUNGSI UTAMA ---

int main() {
    dpp::cluster bot(BOT_TOKEN);
    bot.on_log(dpp::utility::log_info());

    // --- PENANGANAN KLIK TOMBOL ---
    bot.on_button_click([&bot](const dpp::button_click_t& event) {
        if (event.command.get_issuing_user().id != dpp::snowflake(OWNER_ID)) {
            event.reply("Akses Ditolak.");
            return;
        }

        std::string id = event.custom_id;

        if (id == "btn_start") {
            std::string start_cmd = "su -c monkey -p " + ROBLOX_PKG + " -c android.intent.category.LAUNCHER 1 > /dev/null 2>&1";
            system(start_cmd.c_str());
            
            event.reply(CreatePanelMessage("Status: Mencoba membuka Roblox..."));
            bot.message_delete(event.command.msg.id, event.command.channel_id);
        }
        else if (id == "btn_vip") {
            // Memaksa Android membuka link yang memicu launch aplikasi Roblox
            std::string vip_cmd = "su -c am start -a android.intent.action.VIEW -d \"" + VIP_SERVER_LINK + "\" > /dev/null 2>&1";
            system(vip_cmd.c_str());
            
            event.reply(CreatePanelMessage("Status: Mencoba menghubungkan ke Private Server..."));
            bot.message_delete(event.command.msg.id, event.command.channel_id);
        }
        else if (id == "btn_stop") {
            auto_recovery = false;
            std::string stop_cmd = "su -c am force-stop " + ROBLOX_PKG;
            system(stop_cmd.c_str());
            
            event.reply(CreatePanelMessage("Status: Roblox di-force stop dan Auto-Recovery dimatikan."));
            bot.message_delete(event.command.msg.id, event.command.channel_id);
        }
        else if (id == "btn_ss") {
            event.thinking(); 
            TakeScreenshot();
            
            dpp::message msg = CreatePanelMessage("Status: Tangkapan layar berhasil diambil.");
            msg.add_file("screenshot.png", dpp::utility::read_file(SS_PATH));
            
            event.edit_original_response(msg); 
            bot.message_delete(event.command.msg.id, event.command.channel_id); 
        }
        else if (id == "btn_hw") {
            std::string status = GetDetailedStatus();
            std::string formatted_status = "```ini\n" + status + "\n```";
            
            event.reply(CreatePanelMessage(formatted_status));
            bot.message_delete(event.command.msg.id, event.command.channel_id);
        }
        else if (id == "btn_rec") {
            auto_recovery = !auto_recovery;
            std::string state = auto_recovery ? "AKTIF" : "NONAKTIF";
            
            event.reply(CreatePanelMessage("Status Auto-Recovery: " + state));
            bot.message_delete(event.command.msg.id, event.command.channel_id);
        }
    });

    // --- PENANGANAN SLASH COMMAND ---
    bot.on_slashcommand([&bot](const dpp::slashcommand_t& event) {
        if (event.command.get_issuing_user().id != dpp::snowflake(OWNER_ID)) {
            event.reply("Akses Ditolak.");
            return;
        }

        std::string cmd_name = event.command.get_command_name();

        if (cmd_name == "panel") {
            event.reply(CreatePanelMessage("Kontrol Panel Roblox Termux"));
        }
        else if (cmd_name == "update") {
            dpp::snowflake file_id = std::get<dpp::snowflake>(event.get_parameter("file"));
            dpp::attachment att = event.command.resolved.attachments[file_id];
            
            if (att.filename.find(".cpp") == std::string::npos) {
                event.reply("Pembaruan gagal. Harap lampirkan file berekstensi .cpp");
                return;
            }

            event.reply("Mengunduh skrip baru dan memulai kompilasi di latar belakang...");
            std::string dl_cmd = "curl -sL -o bot_termux.cpp \"" + att.url + "\" && bash recompile.sh &";
            system(dl_cmd.c_str());
        }
    });

    bot.on_ready([&bot](const dpp::ready_t& event) {
        if (dpp::run_once<struct register_bot_commands>()) {
            dpp::slashcommand panel_cmd("panel", "Munculkan panel kontrol UI", bot.me.id);
            dpp::slashcommand update_cmd("update", "Update script bot via lampiran", bot.me.id);
            update_cmd.add_option(dpp::command_option(dpp::co_attachment, "file", "File script .cpp baru", true));

            bot.global_bulk_command_create({panel_cmd, update_cmd});
        }
        
        // Loop Auto Recovery
        std::thread([&]() {
            while (true) {
                if (auto_recovery && !IsRobloxRunning()) {
                    std::cout << "[Auto-Recovery] Roblox mati, menyambungkan kembali ke VIP Server..." << std::endl;
                    // Saat recovery aktif, lebih baik menggunakan VIP link agar langsung masuk ke server Anda
                    std::string vip_cmd = "su -c am start -a android.intent.action.VIEW -d \"" + VIP_SERVER_LINK + "\" > /dev/null 2>&1";
                    system(vip_cmd.c_str());
                }
                std::this_thread::sleep_for(std::chrono::seconds(20));
            }
        }).detach();
    });

    bot.start(dpp::st_wait);
    return 0;
}
