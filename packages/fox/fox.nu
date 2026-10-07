# Log in to Fox (fox.educloud.no) with the one-time code and password from 1Password.
# Fox refuses SSH keys, so this types both prompts once; the `fox` host in ~/.ssh/config
# keeps the connection open and later `ssh fox` and `scp fox:...` calls reuse it.
def main [] {
    with-env {
        FOX_OTP: (^op item get Educloud --otp)
        FOX_PASSWORD: (^op read "op://Personal/Educloud/password")
    } {
        ^expect -c '
            spawn ssh fox
            expect "One-Time_Code:" { send "$env(FOX_OTP)\r" }
            expect "Password:"      { send "$env(FOX_PASSWORD)\r" }
            interact'
    }
}
