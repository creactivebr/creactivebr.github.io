---
layout: post
title: "XData - como manipular dados adicionais nos objetos? (Parte II)"
category: posts
author: brunosaboia
tags: [AutoCAD, XData]
---

Olá a todos,

Essa é a segunda parte do post sobre como manipular XData no AutoCAD. Se você não tem muita certeza dos conceitos, [dê uma olhada]({% post_url 2013-09-13-xdata---como-manipular-dados-adicionais-nos-objetos-parte-i %}) no post passado. 


Na verdade, nós começamos ao avesso: primeiro aprendemos a ler, e agora que vamos aprender a escrever. A razão disso é que é um pouco mais complexo salvar do que ler, e muito dos conceitos utilizados são compartilhados por ambas as operações.

Primeiramente, devemos registrar nossa aplicação. Para isto, devemos acessar a tabela de registro de aplicações. O código abaixo registra uma aplicação com o nome que passarmos:

{% highlight csharp linenos=table %}
static void RegistrarApp(string nome)
{
    var documento = Application.DocumentManager.MdiActiveDocument;
    var banco = documento.Database;

    
    using (var transacao = documento.TransactionManager.StartTransaction())
    {
        var tabela = transacao.GetObject(banco.RegAppTableId, OpenMode.ForRead, false) as RegAppTable;

        if (tabela == null)
            return;

        if (!tabela.Has(nome))
        {
            tabela.UpgradeOpen();
            var registro = new RegAppTableRecord();
            registro.Name = nome;
            tabela.Add(registro);
            transacao.AddNewlyCreatedDBObject(registro, true);
        }
        transacao.Commit();
    }
}
{% endhighlight %}

Depois disso, nós precisamos salvar efetivamente a informação que desejamos (no caso, um nome para a linha). Ao código:

{% highlight csharp linenos=table %}
[CommandMethod("SalvarNome")]
static public void SalvarNome()
{
    var documento = Application.DocumentManager.MdiActiveDocument;
    var editor = documento.Editor;
    var nomeApp = "AppTesteXData";

    var opcoesNome = new PromptStringOptions("\nDigite um nome para a entidade: ");
    opcoesNome.AllowSpaces = true;
    var resultadoNome = editor.GetString(opcoesNome);
    if (resultadoNome.Status != PromptStatus.OK)
    {
        editor.WriteMessage("\nComando abortado.");
    }

    var opcoesSelEntidade = new PromptEntityOptions("\nSelecione uma entidade: ");
    var resultadoEntidade = editor.GetEntity(opcoesSelEntidade);

    if (resultadoEntidade.Status != PromptStatus.OK)
    {
        editor.WriteMessage("\nComando abortado.");
    }

    using (var transacao = documento.TransactionManager.StartTransaction())
    {
        DBObject objeto = transacao.GetObject(resultadoEntidade.ObjectId, OpenMode.ForWrite);
        if(objeto == null) return;
        
        RegistrarApp(nomeApp);
        var buffer = new ResultBuffer(
            new TypedValue((short)DxfCode.ExtendedDataRegAppName, nomeApp),
            new TypedValue((short)DxfCode.ExtendedDataAsciiString, resultadoNome.StringResult)
          );
        objeto.XData = buffer;
        buffer.Dispose();
        transacao.Commit();
        editor.WriteMessage("\nDados salvos com sucesso!");
    }
}
{% endhighlight %}

Se você tem acompanhado o blog, a única coisa que pareça novidade é a parte que adiciona o buffer. Bem, é simples de entender. Um TypedValue é uma classe do tipo chave-valor. O DxfCode é apenas um alias para facilitar a obtenção da chave que precisamos. No caso, o primeiro item do buffer é do tipo ExtendedDataRegAppName, que vai carregar o nome que registramos previamente (com o método RegistrarApp), e seu valor é uma string. O segundo item é a string que representa o nome da linha de fato, ou seja, o dado que realmente nos importa. O DxfCode é ExtendedDataAsciiString, ou seja, uma string ASCII que será salva no objeto (é importante lembrar do encoding nesse caso: nada de acentos). Depois, apenas salvamos o buffer no XData da entidade, e pronto. Temos agora o dado salvo na entidade.

Podemos conferir o resultado salvando. Digitamos o comando, selecionamos a entidade e observamos que o comando foi bem sucedido:

![Fig. 1 Rodando o comando]({{ site_url }}/images/xdata---como-manipular-dados-adicionais-nos-objetos-parte-ii-.img1.png)

![Fig. 2 Selecionado a entidade]({{ site_url }}/images/xdata---como-manipular-dados-adicionais-nos-objetos-parte-ii-.img2.png)

![Fig. 3 OK, nome inserido!]({{ site_url }}/images/xdata---como-manipular-dados-adicionais-nos-objetos-parte-ii-.img3.png)

Pronto, agora os dados foram inseridos na nossa entidade. Você pode confiar em mim! Ou... se você não confia tanto :(, pode executar o comando de leitura que [criamos no post passado]({% post_url 2013-09-13-xdata---como-manipular-dados-adicionais-nos-objetos-parte-i %}):

![Fig. 4 Verificando a inserção]({{ site_url }}/images/xdata---como-manipular-dados-adicionais-nos-objetos-parte-ii-.img4.png)

Segue o código completo coberta na série sobre XData:

{% highlight csharp linenos=table %}
using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.EditorInput;
using Autodesk.AutoCAD.Runtime;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ExemploXDataAutoCAD
{
    public class Main
    {
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
                        editor.WriteMessage("\nTipo: {0} , Valor: {1}", valor.TypeCode.ToString(), valor.Value.ToString());
                    }
                }
            }
        }

        static void RegistrarApp(string nome)
        {
            var documento = Application.DocumentManager.MdiActiveDocument;
            var banco = documento.Database;

            
            using (var transacao = documento.TransactionManager.StartTransaction())
            {
                var tabela = transacao.GetObject(banco.RegAppTableId, OpenMode.ForRead, false) as RegAppTable;

                if (tabela == null)
                    return;

                if (!tabela.Has(nome))
                {
                    tabela.UpgradeOpen();
                    var registro = new RegAppTableRecord();
                    registro.Name = nome;
                    tabela.Add(registro);
                    transacao.AddNewlyCreatedDBObject(registro, true);
                }
                transacao.Commit();
            }
        }

        [CommandMethod("SalvarNome")]
        static public void SalvarNome()
        {
            var documento = Application.DocumentManager.MdiActiveDocument;
            var editor = documento.Editor;
            var nomeApp = "AppTesteXData";

            var opcoesNome = new PromptStringOptions("\nDigite um nome para a entidade: ");
            opcoesNome.AllowSpaces = true;
            var resultadoNome = editor.GetString(opcoesNome);
            if (resultadoNome.Status != PromptStatus.OK)
            {
                editor.WriteMessage("\nComando abortado.");
            }

            var opcoesSelEntidade = new PromptEntityOptions("\nSelecione uma entidade: ");
            var resultadoEntidade = editor.GetEntity(opcoesSelEntidade);

            if (resultadoEntidade.Status != PromptStatus.OK)
            {
                editor.WriteMessage("\nComando abortado.");
            }

            if (resultadoEntidade.ObjectId == ObjectId.Null) return;

            using (var transacao = documento.TransactionManager.StartTransaction())
            {
                DBObject objeto = transacao.GetObject(resultadoEntidade.ObjectId, OpenMode.ForWrite);
   
                RegistrarApp(nomeApp);
                var buffer = new ResultBuffer(
                    new TypedValue((short)DxfCode.ExtendedDataRegAppName, nomeApp),
                    new TypedValue((short)DxfCode.ExtendedDataAsciiString, resultadoNome.StringResult)
                  );
                objeto.XData = buffer;
                buffer.Dispose();
                transacao.Commit();
                editor.WriteMessage("\nDados salvos com sucesso!");
            }
        }
    }
}
{% endhighlight %}

Abraço e até a próxima!



