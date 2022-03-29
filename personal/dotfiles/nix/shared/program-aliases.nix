{ }: {
    ls = "exa";
    # Unfortunately zoxide relies on cd in Fish so can't do: cd = "z";
    vim = "nvim";
    vi = "nvim";
    # TODO: Bug in alises. Shouldn't need escaping
    upstream-push = ''
        echo \"git push --set-upstream (git remote show) (git branch --show-current)\" | fish
    '';
    delete-branches-already-merged-to-master = ''
        git branch --merged master | grep -v -e master| xargs -n 1 git branch -d
    '';
    delete-branches-already-merged-to-main = ''
        git branch --merged main | grep -v -e master| xargs -n 1 git branch -d
    '';
    push = ''
        git push
    '';
    commit-all-git = ''
        git add . && git commit
    '';
    stop-all-containers = ''
        echo \"docker stop (docker ps -q)\" | fish
    '';
    remove-all-containers=''
        echo \"docker rm (docker container ls -aq)\" | fish
    '';
    remove-all-images=''
        echo \"docker rmi (docker images -aq)\" | fish
    '';
}