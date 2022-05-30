local package = game.ServerScriptService.Slick

package.Parent = game.ReplicatedStorage.Packages

require(package.Parent.TestEZ).TestBootstrap:run({
	package["Signal.spec"],
	package.Signal["Connection.spec"],
	
	package["Card.spec"],
	package["Store.spec"],
	package["Keeper.spec"],

	package.Reducers["Standard.spec"],
})
