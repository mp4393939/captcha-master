require 'nn';

local train = {}


function train.accuracy(Xv,Yv,net,batch)
    net:evaluate()
    local batch = batch or 64
    local Nv = Xv:size(1)
    local lloss = 0
    for i =1,Nv,batch do
        local j = math.min(i+batch-1,Nv)
        local Xb = Xv[{{i,j}}]:cuda()
        local Yb = Yv[{{i,j}}]:cuda()
        local out = net:forward(Xb) -- N*k*C
        local tmp,YYb = out:max(3)
        lloss = lloss + YYb:eq(Yb):sum()
    end
    return (100*lloss/(5*Nv))
end


function train.accuracyK(Xv,Yv,net,batch)
    net:evaluate()
    local batch = batch or 64
    local Nv = Xv:size(1)
    local lloss = 0
    for i =1,Nv,batch do
        local j = math.min(i+batch-1,Nv)
        local Xb = Xv[{{i,j}}]:cuda()
        local Yb = Yv[{{i,j}}]:cuda()
        local out = net:forward(Xb) -- N*k*C
        local tmp,YYb = out:max(3)
        lloss = lloss + YYb:eq(Yb):sum(2):eq(5):sum()
    end
    return (100*lloss/(Nv))
end


function train.sgd(net,ct,Xt,Yt,Xv,Yv,K,sgd_config,batch)
    local x,dx = net:getParameters()
    require 'optim'
    local batch = batch or 64
    local Nt = Xt:size(1)
    print('parameters size ..')
    print(#x)
    for k=1,K do
        local lloss = 0
        net:training()

        for i =1,Nt,batch do
            
            dx:zero()
            local j = math.min(i+batch-1,Nt)
            local Xb = Xt[{{i,j}}]:cuda()
            local Yb = Yt[{{i,j}}]:cuda()
            local out = net:forward(Xb)
            local loss = ct:forward(out,Yb)
            local dout = ct:backward(out,Yb)
            net:backward(Xb,dout)
            dx:div(j-i+1)
            function feval()
                return loss,dx
            end
            local ltmp,tmp = optim.sgd(feval,x,sgd_config)
            --print(loss)
            lloss = lloss + loss
        end
        print('loss..'..lloss)
        print('valid .. '.. train.accuracy(Xv,Yv,net,batch))
        print('train .. '.. train.accuracy(Xt,Yt,net,batch))
        print('valid .. '.. train.accuracyK(Xv,Yv,net,batch))
        print('train .. '.. train.accuracyK(Xt,Yt,net,batch))
    end
end


return train
