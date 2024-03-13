.PHONY: deploy
deploy:
	forge script script/FourDollarV1.s.sol --rpc-url $(network) --broadcast --verify -vvvv