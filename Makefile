all: clean hgstatus
	
clean:
	rm -rf log/ tmp/
	rm -f config/environments/common_conf.rb
	rm -f config/environments/development.rb
	rm -f config/environments/production.rb
	@echo

hgstatus:
	hg status
	@echo


