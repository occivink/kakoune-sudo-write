# save the current buffer to its file as root
# (optionally pass the user password to sudo if not cached)

declare-option -hidden str sudo_write_tmp

define-command -hidden sudo-write-impl %{
    %sh{
        echo "set-option buffer sudo_write_tmp '$(mktemp --tmpdir XXXXXXXX)'"
    }
    write %opt{sudo_write_tmp}
    %sh{
        sudo -- dd if="$kak_opt_sudo_write_tmp" of="$kak_buffile" >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo "edit!"
        else
            echo "echo -markup '{Error}Something went wrong'"
        fi
        rm -f "$kak_opt_sudo_write_tmp"
    }
    unset-option buffer sudo_write_tmp
}

define-command -hidden -params 1 cache-password %{
    eval -no-hooks -draft %{
        edit -scratch *sudo_write_pass*
        reg '"' %arg{1}
        exec "<a-p>|sudo -S echo ok<ret>"
        try %{
            exec <a-k>ok<ret>
            delete-buffer
        } catch %{
            delete-buffer
            fail
        }
    }
}

def sudo-write -docstring "Write the content of the buffer using sudo" %{
    %sh{
        # check if the password is cached
        if sudo -n true > /dev/null 2>&1; then
            echo "sudo-write-impl"
        else
            # if not, ask for it
            echo "prompt -password 'Password: ' %{
                try %{
                    cache-password %val{text}
                    sudo-write-impl
                } catch %{
                    echo -markup '{Error}Incorrect password'
                }
            }"
        fi
    }
}

