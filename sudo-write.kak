# save the current buffer to its file as root
# (optionally pass the user password to sudo if not cached)

define-command -hidden sudo-write-impl %{
    eval -save-regs f %{
        # TOOD this could take the content of the buffer from stdin instead
        reg f %sh{ mktemp --tmpdir XXXXX }
        write %reg{f}
        eval %sh{
            sudo -n -- dd if="$kak_main_reg_f" of="$kak_buffile" >/dev/null 2>&1
            if [ $? -eq 0 ]; then
                echo "edit!"
            else
                echo "echo -markup '{Error}Something went wrong'"
            fi
            rm -f "$kak_main_reg_f"
        }
    }
}

define-command -hidden -params 1 sudo-cache-password %{
    eval -no-hooks -save-regs '"c' %{
        eval -draft %{
            edit -scratch *sudo-write-pass*
            reg '"' %arg{1}
            exec "<a-p>|sudo -S echo ok<ret>"
            try %{
                exec '%H<a-k>ok<ret>'
                reg c nop
            } catch %{
                reg c fail
            }
        }
        delete-buffer *sudo-write-pass*
        eval %reg{c}
    }
}

define-command -hidden sudo-prompt-password %{
    prompt -password 'Password:' %{
        try %{
            sudo-cache-password %val{text}
            sudo-write-impl
        } catch %{
            echo -markup '{Error}Incorrect password'
        }
    }
}

define-command sudo-write -docstring "Write the content of the buffer using sudo" %{
    %sh{
        # check if the password is cached
        if sudo -n true > /dev/null 2>&1; then
            echo sudo-write-impl
        else
            echo sudo-prompt-password
        fi
    }
}

