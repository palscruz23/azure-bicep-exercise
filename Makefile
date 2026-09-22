.PHONY: update

update:
	git add .
	git commit -m "Update"
	git push origin main
	git push github main
