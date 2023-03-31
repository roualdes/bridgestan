using BridgeStan
using Suppressor

m = BridgeStan.StanModel("test_models/multi/multi_model.so", "test_models/multi/multi.data.json")

function f()
    println("Hi from Julia")
    BridgeStan.log_density(m, [1.5,2.5,3.5,4.5,5.5,6.5,7.5,8.5,9.5,10.5])
end

out = @capture_out f()

@assert out == "Hi from Julia\nhi from Stan!\n"
