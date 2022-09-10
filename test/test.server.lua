local package = game.ServerScriptService.Slick

package.Parent = game.ReplicatedStorage.Packages

require(package.Parent.TestEZ).TestBootstrap:run({
	package["Store.spec"],
	package.Reducers["Standard.spec"],
})
