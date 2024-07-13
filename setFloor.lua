local args = {...}
for i=1,args[1] do
    turtle.digDown()
    turtle.placeDown()
    turtle.dig()
    turtle.forward()
end