#!/usr/bin/env python3
import requests
import urllib.parse
import json
import socket
import time
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
import base64

# --- НАСТРОЙКИ ---
SUB_URL = "https://sub.white-dev.pro/LywXmvkM7n5xAZL2"
CONFIG_PATH = "/etc/sing-box/config.json"
GUI_APP = "wofi"
# -----------------

def parse_vless(url):
    parsed = urllib.parse.urlparse(url)
    if not parsed.netloc:
        return None
    
    try:
        # Разбиваем user:pass@host:port
        auth_part, netloc_part = parsed.netloc.split('@')
        uuid = auth_part
        host, port = netloc_part.split(':')
    except ValueError:
        return None
        
    query = urllib.parse.parse_qs(parsed.query)
    tag = urllib.parse.unquote(parsed.fragment) or host
    
    outbound = {
        "type": "vless",
        "tag": tag,
        "server": host,
        "server_port": int(port),
        "uuid": uuid,
        "packet_encoding": "xudp"
    }

    if query.get('security', [''])[0] == 'reality':
        outbound["tls"] = {
            "enabled": True,
            "server_name": query.get('sni', [''])[0],
            "utls": {"enabled": True, "fingerprint": query.get('fp', ['chrome'])[0]},
            "reality": {
                "enabled": True,
                "public_key": query.get('pbk', [''])[0],
                "short_id": query.get('sid', [''])[0]
            }
        }
    
    if query.get('flow', [''])[0]:
        outbound["flow"] = query.get('flow')[0]

    t_type = query.get('type', ['tcp'])[0]
    if t_type == 'grpc':
        outbound["transport"] = {
            "type": "grpc",
            "service_name": query.get('serviceName', [''])[0]
        }
    return outbound

def tcp_ping(proxies):
    def ping(p):
        try:
            start = time.time()
            s = socket.create_connection((p['server'], p['server_port']), timeout=1.5)
            s.close()
            return p, (time.time() - start) * 1000
        except:
            return p, float('inf')

    with ThreadPoolExecutor(max_workers=15) as ex:
        results = list(ex.map(ping, proxies))
    return sorted(results, key=lambda x: x[1])

def generate_config(selected_proxy):
    return {
        "log": {"level": "info"},
        "dns": {
            "servers": [
                {"tag": "dns-remote", "address": "https://1.1.1.1/dns-query", "detour": "proxy"},
                {"tag": "dns-direct", "address": "8.8.8.8", "detour": "direct"}
            ],
            "rules": [{"outbound": "any", "server": "dns-direct"}]
        },
        "inbounds": [{
            "type": "tun",
            "inet4_address": "172.19.0.1/30",
            "auto_route": True,
            "strict_route": True,
            "sniff": True
        }],
        "outbounds": [
            {**selected_proxy, "tag": "proxy"},
            {"type": "direct", "tag": "direct"},
            {"type": "dns", "tag": "dns-out"}
        ],
        "route": {
            "rules": [
                {"protocol": "dns", "outbound": "dns-out"},
                {"geoip": ["private"], "outbound": "direct"}
            ]
        }
    }


def decode_data(raw_content):
    """Пробует декодировать Base64, если это необходимо"""
    content = raw_content.strip()
    # Если контент уже содержит vless://, декодирование не нужно
    if "vless://" in content:
        return content
    
    try:
        # Исправляем padding (добавляем '=' в конец, если нужно)
        missing_padding = len(content) % 4
        if missing_padding:
            content += '=' * (4 - missing_padding)
        return base64.b64decode(content).decode('utf-8')
    except Exception as e:
        return content


def main():
    headers = {'User-Agent': 'curl/8.1.2'}
    
    try:
        # Используем requests для получения данных
        response = requests.get(SUB_URL, headers=headers, timeout=10)
        response.raise_for_status() # Выкинет исключение при 4xx/5xx ошибках

        data = decode_data(response.text)
    except Exception as e:
        subprocess.run(["notify-send", "VPN Error", f"Failed to fetch sub: {e}"])
        sys.exit(1)

    urls = [line.strip() for line in data.splitlines() if line.startswith('vless://')]
    proxies = [p for p in (parse_vless(u) for u in urls) if p]
    
    if not proxies:
        subprocess.run(["notify-send", "VPN Error", "No valid VLESS links found"])
        sys.exit(1)
        
    subprocess.run(["notify-send", "VPN", f"Пингуем {len(proxies)} серверов..."])
    results = tcp_ping(proxies)

    menu_items = []
    for i, (p, ms) in enumerate(results):
        status = f"{int(ms)}ms" if ms != float('inf') else "DEAD"
        menu_items.append(f"{i} | {status} | {p['tag']}")

    wofi_input = "\n".join(menu_items).encode('utf-8')
    wofi_cmd = ["wofi", "--dmenu", "--prompt", "Select VPN", "--lines", "15"]
    
    try:
        proc = subprocess.run(wofi_cmd, input=wofi_input, capture_output=True, check=True)
        choice_str = proc.stdout.decode('utf-8').strip()
        if not choice_str:
            sys.exit(0)
        choice_idx = int(choice_str.split('|')[0].strip())
    except (subprocess.CalledProcessError, ValueError, IndexError):
        sys.exit(0)

    selected = results[choice_idx][0]
    config = generate_config(selected)

    tmp_path = "/tmp/sing-box.json"
    with open(tmp_path, "w") as f:
        json.dump(config, f, indent=4)

    subprocess.run(["notify-send", "VPN", f"Подключение к {selected['tag']}..."])
    
    apply_cmd = f"pkexec sh -c 'mv {tmp_path} {CONFIG_PATH} && systemctl restart sing-box'"
    subprocess.run(apply_cmd, shell=True)
    subprocess.run(["notify-send", "VPN", "Успешно подключено!"])

if __name__ == "__main__":
    main()

