context := homelab
action := --apply

deploy:
	helmsman $(options) -p 12 --show-diff $(action) -f $(context).yaml

destroy: action := --destroy
destroy: deploy
