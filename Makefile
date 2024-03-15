.PHONY: deploy
deploy:
	forge script script/FourDollarV1.s.sol:FourDollarV1Script --rpc-url $(network) --broadcast --verify -vvvv

withdraw:
	forge script script/FourDollarV1.s.sol:WithdrawScript --rpc-url $(network) --broadcast --verify -vvvv