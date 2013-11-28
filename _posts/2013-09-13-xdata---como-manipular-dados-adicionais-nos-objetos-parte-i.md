---
layout: post
title: "XData - como manipular dados adicionais nos objetos? (Parte I)"
category: posts
author: brunosaboia
tags: [AutoCAD, XData]
---

Olá a todos,

Este tópico é de importância fundamental em vários aspectos práticos do desenvolvimento para AutoCAD. Por muitas vezes, podemos nos ater apenas às informações já contidas nos objetos para manipularmos satisfatoriamente os dados. Porém, em certas ocasiões, é necessário ir além, criando novas propriedades aos objetos de acordo com nossas necessidades. Para tal feito, é necessário que utilizemos o conceito de XData.

Primeiramente, algumas informações sobre a forma. Dividi o post em duas partes, pois o conteúdo é longo. Essa primeira parte introdutória nos mostrará como ler o XData — e a segunda, como salvá-lo.

Para introduzir o conceito, vamos às apresentações formais. XData significa Extended Entity Data, ou dados de extensão da entidade. O seu nome praticamente passa toda a ideia por trás do conceito: criar uma extensão dos dados que queremos. Ou seja, se eu quero dar um nome a uma reta, utilizarei XData para salvar a string que representa o nome do objeto. É exatamente isto que iremos fazer nesse exemplo: adicionar um nome a uma reta (Line).

Um pequeno parêntese. Algumas pessoas podem se perguntar porque simplesmente não criar um bloco e nomeá-lo, ao invés de criar uma reta contendo um nome. Bem, isto não funcionaria muito bem em alguns cenários. Um bloco não tem algumas propriedades essenciais a uma gama de possíveis utilizações do AutoCAD, como propriedades geométricas que uma linha possui. E também nossa preocupação é com o exercício da API, não com aplicações práticas, apesar de eu garantir que, neste caso, a teoria se aplica a prática. Eu já necessitei criar linhas nomeadas no AutoCAD.

Continuando... o XData é um "mecanismo legado" para anexar informações adicionais às entidades. O termo "legado" está sendo empregado aqui porque existem limites inerentes ao uso do XData, por se tratar de um conceito antigo no AutoCAD. O limite global de memória é de 16 KBytes por objeto. Pode ser pouco para suas necessidades. Neste caso, é recomendado que se utilize o mecanismo de XRecords + Extension Dictionaries. Nós abordaremos o conceito em um tópico no futuro.

Agora, ao trabalho. Primeiro. vamos pensar no design do nosso código. Existirão basicamente dois métodos que serão expostos por comandos: um para ler e o outro para escrever a nossa informação. Iremos chamar esses comandos de LerNome e SalvarNome, respectivamente. Em um post passado, explicamos como criar comandos. É interessante dar uma lida, caso não saiba do que estamos falando.

Primeiro, o código de ler o XData:
{% highlight csharp linenos=table %}
[CommandMethod("LerNome")]
public static void LerNome()
{
    var documento = Application.DocumentManager.MdiActiveDocument;
    var editor = documento.Editor;

    var opcoes = new PromptEntityOptions("\nSelecione a entidade: ");
    opcoes.SetRejectMessage("\nPor favor, selecione uma reta (Line).");
    opcoes.AddAllowedClass(typeof(Line), false);
    opcoes.AllowNone = false;

    var resultado = editor.GetEntity(opcoes);

    if (resultado.Status != PromptStatus.OK)
    {
        editor.WriteMessage("\nComando abortado.");
        return;
    }

    using (var transacao = documento.TransactionManager.StartTransaction())
    {
        var reta = transacao.GetObject(resultado.ObjectId, OpenMode.ForRead);

        var dados = reta.XData;

        if (dados == null)
        {
            editor.WriteMessage("\nNão há dados anexados à reta.");
        }
        else
        {
            foreach (var valor in dados)
            {
                editor.WriteMessage("\nTipo: {0}, Valor: {1}", valor.TypeCode, valor.Value.ToString());
            }
        }
    }
}
{% endhighlight %}
Como hoje é sexta-feira 13, vamos como diria Jason: por partes.

A primeira linha de código do método criar uma variável que vai conter o documento corrente que está aberto no AutoCAD. É o ideal armazenar essa informação assim que o comando for executado, diminuindo assim as chances do documento corrente mudar durante o curso da execução do método. Se isto acontecer, é bem provável que os resultados finais esperados não serão atingidos de maneira satisfatória.

Em seguida, simplesmente criamos a variável que nos ajudará a termos acesso ao editor do AutoCAD. Esta linha não é estritamente necessária, claro: poderíamos simplesmente substituir editor por documento.Editor. É apenas para deixar claro o que estamos fazendo.

Novamente, iremos criar uma variável, que nos servirá para definir as opções do prompt do AutoCAD, já que precisamos que o usuário indique ao comando qual entidade deverá ser usada para pesquisar os dados em anexo (daí o fato do objeto ser da classe PromptEntityOptions). É como o comando Explode, por exemplo: é necessário que o usuário defina qual objeto ele quer explodir, ou seja, o argumento do comando.

As três linhas seguintes dizem respeito à configuração do prompt. No construtor, definimos a mensagem que aparecerá para o usuário: "Selecione a entidade". Poderíamos, obviamente, mudar essa mensagem para "Selecione uma reta". Em seguida, simplesmente dizemos qual mensagem o usuário irá visualizar caso selecione algo que não queremos. Depois, adicionamos um tipo de classe permitida como seleção (no caso, Line) e, por fim, dizemos que a seleção não pode estar vazia. Abaixo, uma screenshot da execução do comando:

![Fig. 1]({{ site_url }}/images/xdata---como-manipular-dados-adicionais-nos-objetos-parte-i-.img1.png)

Mais uma, desta vez selecionando o retângulo (entidade inválida)...:

![Fig. 2]({{ site_url }}/images/xdata---como-manipular-dados-adicionais-nos-objetos-parte-i-.img2.png)

Note que a entidade não foi aceita: a linha de comando avisa ao usuário para selecionar uma reta. O modo de seleção do AutoCAD ainda está pedindo que uma entidade seja selecionada, como destacamos.

É interessante observar que essa Line herda de DBObject, e não de um objeto de geometria. Nós já falamos sobre esse assunto anteriormente. Existem diferenças cruciais entre as duas classes, e é importante entendê-las no nosso contexto. Basicamente, a classe de geometria possui propriedades e métodos relevantes ao aspecto geométrico, enquanto o DBObject é relacionado, como o nome diz, ao banco de dados do AutoCAD. Como nós estamos interessados no XData, o que importa pra nós são as classes de dados, não as de geometria.

As próximas linhas efetivamente perguntam ao usuário qual a entidade que ele deseja selecionar, e depois analisa o resultado. Se for algo diferente de OK, cancelamos a execução do método. Nada de muito mágico aqui.

Agora é que a coisa fica interessante. Primeiro, criamos uma transação. A keyword using garante que os unmanaged resources (ou seja, recursos que o .NET não gerencia, dois quais o AutoCAD faz uso pesado) da classe sejam despeados uma vez que a execução do bloco seja finalizada. Esse comportamento só é possível porque a classe Transaction herda da interface IDisposable. Como esse assunto foge um pouco do escopo, recomendo a seguinte leitura para quem se interessar mais: http://msdn.microsoft.com/en-us/library/system.idisposable.aspx

Depois, lemos o objeto do banco de dados no modo de leitura, e verificamos o XData anexado. Basicamente, o XData é um objeto da classe ResultBuffer, que é uma coleção de elementos do tipo TypedValue, que por sua vez é uma estrutura que contém o tipo e o valor de um dado. Ufa. Percorremos esses dados e escrevemos o tipo (que é um short) e o valor (que é um object) na tela do editor. Vamos ver o resultado se clicarmos na reta desenhada:

![Fig. 2]({{ site_url }}/images/xdata---como-manipular-dados-adicionais-nos-objetos-parte-i-.img3.png)

Como ainda não salvamos nenhum dado adicional, a linha de comando avisa que não há nenhum dado anexado à reta. Simples, não?

No próximo post, iremos analisar como salvar o XData. Até breve, forte abraço e bom coding a todos!