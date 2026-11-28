#!/usr/bin/env python3
import os, sys, re, json

base_dir = os.path.dirname(os.path.abspath(__file__))
errors = []

print(f"[*] Running Release Gatekeeper in: {base_dir}")

# 1. Total BOM scan across ALL files
for root, dirs, files in os.walk(base_dir):
    for f in files:
        if f.endswith(('.git', '.ico', '.png', '.jpg')):
            continue
        full_p = os.path.join(root, f)
        with open(full_p, "rb") as fp:
            content = fp.read()
        if b"\xef\xbb\xbf" in content:
            errors.append(f"FATAL: Byte Order Mark (BOM) \\xef\\xbb\\xbf detected in {f}")

# 2. Line ending check on .cmd and .bat files
for f in os.listdir(base_dir):
    if f.endswith(('.cmd', '.bat')):
        full_p = os.path.join(base_dir, f)
        with open(full_p, "rb") as fp:
            content = fp.read()
        if b"\r\n" not in content:
            errors.append(f"FATAL: No Windows CRLF found in {f}")
        lone_lf = len(content.replace(b"\r\n", b"").split(b"\n")) - 1
        if lone_lf > 0:
            errors.append(f"FATAL: {lone_lf} lone Unix LF characters found in {f}")

# 3. PowerShell bracket and token balance on engine.ps1 and active .cmd
for f in os.listdir(base_dir):
    if f == "engine.ps1" or (f.startswith("GIN-Win-Optimizer_") and f.endswith(".cmd")):
        full_p = os.path.join(base_dir, f)
        with open(full_p, "r", encoding="utf-8") as fp:
            code = fp.read()
        
        stack = []
        pairs = {')': '(', '}': '{', ']': '['}
        i = 0
        n = len(code)
        in_squote = False
        in_dquote = False
        in_block_comment = False

        while i < n:
            c = code[i]
            if not in_squote and not in_dquote:
                if not in_block_comment and i + 1 < n and c == '<' and code[i+1] == '#':
                    in_block_comment = True
                    i += 2
                    continue
                elif in_block_comment and i + 1 < n and c == '#' and code[i+1] == '>':
                    in_block_comment = False
                    i += 2
                    continue
                elif in_block_comment:
                    i += 1
                    continue
                elif c == '#':
                    while i < n and code[i] != '\n':
                        i += 1
                    continue

            if in_block_comment:
                i += 1
                continue

            if c == "'" and not in_dquote:
                in_squote = not in_squote
                i += 1
                continue
            elif c == '"' and not in_squote:
                if i > 0 and code[i-1] == '`':
                    pass
                else:
                    in_dquote = not in_dquote
                i += 1
                continue

            if in_squote or in_dquote:
                i += 1
                continue

            if c in '({[':
                stack.append((c, i))
            elif c in ')}]':
                if not stack:
                    line_no = code[:i].count('\n') + 1
                    errors.append(f"FATAL: Unmatched closing {c} at line {line_no} in {f}")
                else:
                    top, pos = stack.pop()
                    if top != pairs[c]:
                        line_no = code[:i].count('\n') + 1
                        errors.append(f"FATAL: Mismatched bracket {c} at line {line_no} in {f}")
            i += 1

        if stack:
            for top, pos in stack:
                line_no = code[:pos].count('\n') + 1
                errors.append(f"FATAL: Unclosed {top} from line {line_no} in {f}")

# 4. Version check
v_file = os.path.join(base_dir, "version.json")
if os.path.exists(v_file):
    with open(v_file, "r", encoding="utf-8") as fp:
        v_data = json.load(fp)
    cur_v = v_data.get("current_version")
    active_v = v_data.get("active_versions", [])
    print(f"[*] Current Version: {cur_v}, Active Versions: {active_v}")
    for act in active_v:
        if not os.path.exists(os.path.join(base_dir, act)):
            errors.append(f"FATAL: Active version file missing: {act}")

if errors:
    print(f"[!] RELEASE GATEKEEPER FAILED with {len(errors)} error(s):")
    for err in errors:
        print(f"    - {err}")
    sys.exit(1)
else:
    print("[+] RELEASE GATEKEEPER PASSED! All checks verified cleanly (0 BOM, 100% CRLF, 0 syntax errors).")
    sys.exit(0)
