import socket
import time

HOST = 'foggy-cliff.picoctf.net'
PORT = 61164

def recv_until(sock, prompt='Enter the Linux command to reverse it:', timeout=15):
    sock.settimeout(timeout)
    data = b''
    while True:
        try:
            chunk = sock.recv(4096)
            if not chunk:
                break
            data += chunk
            text = data.decode()
            if prompt in text:
                return text
            if 'picoCTF{' in text:
                return text
        except socket.timeout:
            break
    return data.decode()

def get_cmd(hint):
    h = hint.lower()

    if 'base64' in h:
        return 'base64 -d'
    if 'reversed' in h:
        return 'rev'
    if 'rot13' in h or 'rot 13' in h:
        return "tr 'A-Za-z' 'N-ZA-Mn-za-m'"
    if 'hex' in h or 'hexadecimal' in h:
        return 'xxd -r -p'
    if 'atbash' in h:
        return "tr 'A-Za-z' 'ZYXWVUTSRQPONMLKJIHGFEDCBAzyxwvutsrqponmlkjihgfedcba'"

    # "Replaced X with Y" -> reverse: tr 'Y' 'X'
    if 'replaced ' in h and ' with ' in h:
        import re
        m = re.search(r'replaced\s+(.+?)\s+with\s+(.+?)(?:\.|$)', h)
        if m:
            from_word = m.group(1).strip().rstrip('.')
            to_word = m.group(2).strip().rstrip('.')

            # Map words to actual characters
            word_to_char = {
                'dashes': '-', 'dash': '-', 'hyphens': '-', 'hyphen': '-',
                'underscores': '_', 'underscore': '_',
                'spaces': ' ', 'space': ' ',
                'dots': '.', 'dot': '.',
                'slashes': '/', 'slash': '/',
                'colons': ':', 'colon': ':',
                'semicolons': ';', 'semicolon': ';',
                'pipes': '|', 'pipe': '|',
                'equals': '=', 'equal': '=',
                'plus': '+', 'pluses': '+',
                'stars': '*', 'star': '*',
                'question marks': '?', 'question mark': '?',
                'exclamation marks': '!', 'exclamation mark': '!',
                'at signs': '@', 'at sign': '@',
                'hashes': '#', 'hash': '#',
                'dollars': '$', 'dollar': '$',
                'percents': '%', 'percent': '%',
                'carets': '^', 'caret': '^',
                'ampersands': '&', 'ampersand': '&',
                'tildes': '~', 'tilde': '~',
                'backticks': '`', 'backtick': '`',
                'single quotes': "'", 'single quote': "'",
                'double quotes': '"', 'double quote': '"',
                'commas': ',', 'comma': ',',
                'parentheses': '()', 'parenthesis': '()',
                'brackets': '[]', 'bracket': '[]',
                'curly braces': '{}', 'curly brace': '{}',
                'angle brackets': '<>', 'angle bracket': '<>',
            }

            from_char = word_to_char.get(from_word, from_word)
            to_char = word_to_char.get(to_word, to_word)

            return f"tr '{to_char}' '{from_char}'"

    # "Prepend X" (unrecognized patterns)
    if 'prepend' in h:
        import re
        m = re.search(r'prepend[ed]*\s+(.+)', h)
        if m:
            text = m.group(1).strip().rstrip('.')
            # To remove prepended text from each pipe-separated word: use sed
            return f"sed 's/{text}//g'"

    print(f"  !! Unhandled hint: '{hint}'")
    return None


sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.settimeout(15)
sock.connect((HOST, PORT))

text = recv_until(sock)
print(text)

for step in range(1, 30):
    lines = text.strip().split('\n')
    hint = None
    current_flag = None

    for line in lines:
        if 'Hint:' in line and 'Hint: Try' not in line:
            hint = line.split(':', 1)[1].strip()
        elif line.startswith('Hint '):
            hint = line[5:].strip()
        if line.startswith('Current flag:'):
            current_flag = line.split(':', 1)[1].strip()

    # Handle "Try reversing: X" format
    if not hint:
        for line in lines:
            if 'Try reversing:' in line:
                hint = line.split(':', 1)[1].strip()

    if not hint:
        print(f"Could not find hint in: {text}")
        break

    print(f"\n--- Step {step} ---")
    print(f"  Flag: {current_flag}")
    print(f"  Hint: {hint}")

    cmd = get_cmd(hint)
    if cmd is None:
        print("  Stopping - unknown transformation.")
        break

    print(f"  Cmd: {cmd}")
    sock.sendall((cmd + "\n").encode())
    time.sleep(0.3)

    text = recv_until(sock)

    if 'picoCTF{' in text:
        print(f"\n=== FLAG FOUND! ===")
        print(text)
        break

    if 'Correct!' not in text:
        print(f"  Unexpected response:\n{text}")
        break

sock.close()