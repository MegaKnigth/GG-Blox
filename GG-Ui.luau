-- ===== CONFIGURAÇÕES =====
local URL_BIBLIOTECA = "https://raw.githubusercontent.com/MegaKnigth/GG-Blox/refs/heads/main/Gold-Ui.luau"
local REPO = "https://raw.githubusercontent.com/MegaKnigth/GG-Blox/main/assets/"

local fundos = {
    { nome = "Black", arquivo = "black.jpg", texto = Color3.new(1,1,1),
      tom = Color3.new(0,0,0), tomT = 0.4 },
    { nome = "Miku Code", arquivo = "mikucode.jpg", texto = Color3.new(1,1,1),
      tom = Color3.fromRGB(20,10,40), tomT = 0.45 },
    { nome = "Branco", arquivo = "branco.jpg", texto = Color3.new(1,1,1),
      tom = Color3.fromRGB(10,30,70), tomT = 0.55 },
    { nome = "Hollow", arquivo = "hollow.jpg", texto = Color3.new(1,1,1),
      tom = Color3.fromRGB(10,30,70), tomT = 0.45 },
    { nome = "Miku Mine", arquivo = "mikumine.jpg", texto = Color3.new(1,1,1),
      tom = Color3.fromRGB(40,20,60), tomT = 0.45 },
    { nome = "Re:Zero", arquivo = "rezero.jpg", texto = Color3.fromRGB(30,30,40),
      tom = Color3.new(1,1,1), tomT = 0.35 },
    { nome = "Dragon Ball", arquivo = "dragonball.jpg", texto = Color3.new(1,1,1),
      tom = Color3.new(0,0,0), tomT = 0.4 },
}

-- ===== BIBLIOTECA GOLD =====
local redzlib = loadstring(game:HttpGet(URL_BIBLIOTECA))()

-- Baixa a imagem só na primeira vez e devolve o asset pronto
local function baixar(arquivo)
    if not isfile(arquivo) then
        writefile(arquivo, game:HttpGet(REPO .. arquivo))
    end
    return getcustomasset(arquivo)
end

-- Aplica uma imagem: fundo, tom (5%), cor do texto e quadrado minimizado
local function aplicar(ctx, info)
    ctx.fundo.Image = baixar(info.arquivo)
    ctx.tom.BackgroundColor3 = info.tom
    ctx.tom.BackgroundTransparency = 0.95
    ctx.texto = info.texto

    for _, obj in ipairs(ctx.gui:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            obj.TextColor3 = info.texto
        end
    end

    if ctx.minimizador then
        ctx.minimizador.Image = ctx.fundo.Image
    end
end

-- ===== HOOK NA JANELA =====
local criarJanelaOriginal = redzlib.MakeWindow

redzlib.MakeWindow = function(self, config)
    local janela = criarJanelaOriginal(self, config)
    local main = janela:GetElements().MainFrame
    local gui = main.Parent

    -- Remove o fundo escuro da janela para a imagem aparecer
    main.BackgroundTransparency = 1

    -- Compatibilidade: o script usa MakeNotify, a Gold usa Notify
    redzlib.MakeNotify = function(_, cfg)
        return janela:Notify({
            Title = cfg.Name or cfg.Title,
            Content = cfg.Text or cfg.Content,
            Time = cfg.Time
        })
    end

    -- Fundo atrás de tudo
    local fundo = Instance.new("ImageLabel")
    fundo.Name = "FundoPersonalizado"
    fundo.Size = UDim2.fromScale(1,1)
    fundo.BackgroundTransparency = 1
    fundo.ScaleType = Enum.ScaleType.Crop
    fundo.ZIndex = 0
    fundo.Parent = main
    Instance.new("UICorner", fundo).CornerRadius = UDim.new(0,8)

    -- Camada escura por cima da imagem
    local tom = Instance.new("Frame")
    tom.Name = "Tom"
    tom.Size = UDim2.fromScale(1,1)
    tom.BackgroundColor3 = Color3.new(0,0,0)
    tom.BackgroundTransparency = 0.95
    tom.ZIndex = 0
    tom.Parent = fundo
    Instance.new("UICorner", tom).CornerRadius = UDim.new(0,8)

    -- Quadrado minimizado 1:1 com cantos levemente arredondados
    local minimizador = janela:NewMinimizer(Enum.KeyCode.RightControl)
    local botao = minimizador:CreateMobileMinimizer({
        Size = UDim2.fromOffset(40,40),
        BackgroundTransparency = 0,
        ScaleType = Enum.ScaleType.Crop
    })
    Instance.new("UIAspectRatioConstraint", botao).AspectRatio = 1
    Instance.new("UICorner", botao).CornerRadius = UDim.new(0,8)

    local ctx = {
        fundo = fundo,
        tom = tom,
        gui = gui,
        minimizador = botao,
        texto = Color3.new(1,1,1)
    }

    -- Textos criados depois (outras abas, dropdowns) também recebem a cor
    gui.DescendantAdded:Connect(function(obj)
        if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and ctx.texto then
            task.defer(function()
                obj.TextColor3 = ctx.texto
            end)
        end
    end)

    -- Aba para escolher o fundo
    local aba = janela:MakeTab({"Fundos", "Settings"})
    local nomes = {}
    for _, f in ipairs(fundos) do
        table.insert(nomes, f.nome)
    end

    aba:AddDropdown({
        Name = "Escolher fundo",
        Options = nomes,
        Default = {nomes[1]},
        Flag = "Fundo/Selecionado",
        Callback = function(valor)
            if type(valor) == "table" then valor = valor[1] end
            for _, f in ipairs(fundos) do
                if f.nome == valor then
                    aplicar(ctx, f)
                end
            end
        end
    })

    -- Começa com o primeiro fundo
    aplicar(ctx, fundos[1])

    return janela
end

return redzlib
