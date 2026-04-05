#!/usr/bin/env bash
# Claude Code status line script
# Format: model | ctx:XX% cache:XX% | branch [status] | dir

input=$(cat)

# Parse all fields in a single jq call (tab-separated, one line)
IFS=$'\t' read -r model cwd project ctx_pct cache_pct < <(echo "$input" | jq -r '[
  .model.display_name,
  .workspace.current_dir,
  .workspace.project_dir,
  (
    if .context_window.current_usage != null then
      (
        (.context_window.current_usage.input_tokens
         + .context_window.current_usage.cache_creation_input_tokens
         + .context_window.current_usage.cache_read_input_tokens) as $used |
        ($used * 100 / .context_window.context_window_size) | floor | tostring
      )
    else "0"
    end
  ),
  (
    if .context_window.current_usage != null then
      (
        (.context_window.current_usage.cache_creation_input_tokens
         + .context_window.current_usage.cache_read_input_tokens) as $tc |
        if $tc > 0 then
          (.context_window.current_usage.cache_read_input_tokens * 100 / $tc) | floor | tostring
        else "0"
        end
      )
    else "0"
    end
  )
] | @tsv')

# Context info
ctx_info="ctx:${ctx_pct}% cache:${cache_pct}%"

# Git info
if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null || echo 'detached')
  gst=$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null)
  if [ -z "$gst" ]; then
    state='clean'
  else
    m=$(echo "$gst" | grep -c '^ M' || true)
    a=$(echo "$gst" | grep -c '^A'  || true)
    d=$(echo "$gst" | grep -c '^D'  || true)
    u=$(echo "$gst" | grep -c '^??' || true)
    parts=''
    [ "$m" -gt 0 ] && parts="${parts}~${m}"
    [ "$a" -gt 0 ] && parts="${parts}+${a}"
    [ "$d" -gt 0 ] && parts="${parts}-${d}"
    [ "$u" -gt 0 ] && parts="${parts}?${u}"
    state="$parts"
  fi
  git_info="${branch} [${state}]"
else
  git_info='no-git'
fi

# Directory: show relative to project root when inside it
if [ "$cwd" = "$project" ]; then
  dir='~'
elif [[ "$cwd" == "${project}/"* ]]; then
  dir="~${cwd#$project}"
else
  dir="$cwd"
fi

printf '%s | %s | %s | %s\n' "$model" "$ctx_info" "$git_info" "$dir"
