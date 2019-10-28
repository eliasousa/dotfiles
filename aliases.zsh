# Shortcuts
alias copyssh="pbcopy < $HOME/.ssh/id_rsa.pub"
alias reloadcli="source $HOME/.zshrc"
alias dotfiles="cd ~/.dotfiles"

# Git
alias gst="git status"
alias gco="git checkout"
alias gp="git pull"
alias gl="git log --oneline --decorate --color"

# Open code path
c() { cd ~/Projects/jaya/$1; }
_c() { _files  -W ~/Projects/jaya -/; }
compdef _c c

# Login Aws ECR
lecr(){
  eval $(aws ecr get-login --no-include-email --region us-east-1 | sed 's|https://||')
}

# Kubernetes

# Auth / Context
alias datica="datikube refresh --reuse-session"
alias k_staging="kubectl config use-context pwnhealth-us-staging"
alias k_prod="kubectl config use-context pwnhealth-us-prod"

# Port Forward
alias pf-kibana="kubectl -n logging port-forward service/kibana 5601:5601"
alias pf-grafana="kubectl -n monitoring port-forward service/grafana 3001:3000"
alias pf-prometheus="kubectl -n monitoring port-forward service/prometheus-k8s 9090:9090"
alias pf-alert="kubectl -n monitoring port-forward service/alertmanager-main 9093:9093"
pf-database(){ kubectl -n default port-forward $(kubectl get pods -o=name | grep rds-fwd-socat) 3307:3306 }
pf-replica(){ kubectl -n default port-forward $(kubectl get pods -o=name | grep rds-replica-fwd-socat) 3307:3306 }
# Base functions
k-get-background() { kubectl get pods -n $1 -o=name | grep background -m 1 | cut -d "/" -f 2 }
k-bash() { kubectl exec -it $(k-get-background $1) -n $1 -- bash }
k-rake() { kubectl exec -it $(k-get-background $1) -n $1 -- bundle exec rake $2 }
k-rc() { kubectl exec -it $(k-get-background $1) -n $1 -- bundle exec rails c }

# Generate aliases
namespaces=('labs-qa' 'labs-staging' 'labs-prod' 'gene-staging' 'gene-pre-prod' 'gene-prod' 'index-staging' 'index-prod' 'cit-staging' 'cit-pre-prod' 'cit-prod' )
for namespace in "${namespaces[@]}"
do
  alias "bash-$namespace"="k-bash $namespace"
  alias "rake-$namespace"="k-rake $namespace"
  alias "rc-$namespace"="k-rc $namespace"
done
