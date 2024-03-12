.PHONY: deploy
deploy:
	forge script script/FourDollarV1.s.sol --rpc-url $(NETWORK) --broadcast --verify -vvvv