# Vendored from nix-community/impermanence (upstream).
# Modifications:
# - Added boot.impermanence.enable and home.impermanence.enable feature gates
{
	outputs = { self }: {
		nixosModules.impermanence = import ./nixos.nix;
		nixosModules.home-manager.impermanence = import ./home-manager.nix;
		nixosModule = self.nixosModules.impermanence;
	};
}
