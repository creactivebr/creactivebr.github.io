---
layout: post
title: "Desenhando de maneira programática no AutoCAD: Introdução"
category: posts
author: brunosaboia
tags: [AutoCAD, Drawing, Desenho]
---

Às vezes é necessário, quando desenvolvemos plugins ou ferramentas para o AutoCAD, que algum desenho seja feito no documento. Vários motivos podem levar a isso: um deles é o de facilitar um trabalho repetitivo, criando um comando "macro-like" que irá facilitar a vida do usuário.

Nessa introdução, iremos desenhar uma linha (Line) no AutoCAD, mas a ideia é a mesma para qualquer entidade válida (lembrando que nada nos impede de criarmos nossas próprias entidades).

Antes de mais nada, necessitamos fazer uma pequena distinção entre objetos de geometria e objetos de banco de dados. Os objetos de geometria nos auxiliam no desenho, e os objetos de banco de dados são efetivamente salvos no Database do AutoCAD, e possuem portanto algumas propriedades a mais que não interessam à geometria pura (como XData e ObjectId, por exemplo. Iremos falar mais desses conceitos em outro tópico).

Para fins de exemplo, iremos desenhar um quadrado cujo lado será 100. Esse quadrado terá início na origem (ponto 0,0,0).

Primeiramente, vamos criar um novo projeto no Visual Studio Express, clicando em File->New Project.. (ou apertando Ctrl + Shift + N):

![Fig. 1]({{ site_url }}/images/desenhando-de-maneira-programtica-no-autocad-introduo.img1.png)

O projeto deve ser do tipo Class Library. Vamos dar a ele o nome de "DesenharQuadrado":

![Fig. 2]({{ site_url }}/images/desenhando-de-maneira-programtica-no-autocad-introduo.img2.png)

Agora, iremos renomear o arquivo Class1.cs para AuxiliarAutoCAD.cs. Ao fazê-lo, o Visual Studio perguntará se você quer alterar o nome da classe subjacente. Responda que sim, e o nome da classe será automaticamente atualizado para refletir o nome do arquivo:

![Fig. 3]({{ site_url }}/images/desenhando-de-maneira-programtica-no-autocad-introduo.img3.png)

Até agora, nada difere este projeto do que um outro projeto qualquer que não é relacionado ao AutoCAD. Mas agora as coisas ficam um pouco diferentes. Vamos adicionar as referências ao ObjectARX, que é a biblioteca de classes da Autodesk que nos permite programar para os seus sistemas. No Solution Explorer, clicamos com o botão direito em References->Add Reference...

![Fig. 4]({{ site_url }}/images/desenhando-de-maneira-programtica-no-autocad-introduo.img4.png)


Agora, vá até o local onde você descompactou o ObjectARX e selecione os arquivos AcCoreMgd.dll, AcDbMgd.dll e AcMgd.dll. Se você ainda não baixou o ObjectARX, clique [aqui]({{ site_url }}/posts/dlls-do-autocad-objectarx/). Esse é um post do nosso blog que contém informações sobre as DLLs, e também um link para fazer o download do ObjectARX 2013.

Como a nossa ideia é criar um comando para desenhar nosso quadrado, primeiro devemos criar o método que irá chamar o comando. Para isso, devemos usar o Attribute [CommandMethod], que indica que o método subsequente é um comando no AutoCAD. Primeiro, adicione o namespace Autodesk.AutoCAD.Runtime com o comando using. Depois, defina um método chamado DesenharQuadrado que não recebe argumentos e cuja assinatura é void. Depois, adicione o atributto [CommandMethod("DesenharQuadrado")] ao método recém-criado. Nosso código ficará assim:

{% highlight csharp linenos %}
        [CommandMethod("DesenharQuadrado")]
        public void DesenharQuadrado()
        {
        }
{% endhighlight %}



Um quadrado tem quatro vértices, e cada vértice é representado por um ponto (A,B,C e D), como na imagem abaixo:

![Fig. 5 Quadrilátero]({{ site_url }}/images/desenhando-de-maneira-programtica-no-autocad-introduo.img5.JPG)

No nosso exemplo, diremos que a origem é o ponto C, ou seja, as coordenadas do ponto C são (0,0,0). Como estabelecemos um lado de 100, então o ponto A tem coordenadas (0,100,0), o ponto B (100,100,0) e o ponto D (100,0,0). Lembrando que estamos num espaço 3D, portanto as coordenadas são X, Y e Z. Apesar de nosso quadrado não ter dimensão no sentido Z, devemos passar o argumento para o construtor da classe Point3d.

Ao código, então:

{% highlight csharp linenos %}
            var pontoA = new Point3d(0, 100, 0);
            var pontoB = new Point3d(100, 100, 0);
            var pontoC = new Point3d(0, 0, 0);
            var pontoD = new Point3d(100, 0, 0);
{% endhighlight %}



Note que temos 4 pontos criados, mas eles não são suficientes. É necessários uni-los através de quatro retas: AB, AC, BD, CD. Para tal, criamos o objeto Line, que representa a reta, e passamos os pontos de início e fim como argumentos para o construtor:


{% highlight csharp linenos %}
            var retaAB = new Line(pontoA, pontoB);
            var retaAC = new Line(pontoA, pontoC);
            var retaBD = new Line(pontoB, pontoD);
            var retaCD = new Line(pontoC, pontoD);
{% endhighlight %}

Note que, apesar de termos a geometria construída em memória, nós não a adicionamos efetivamente ao documento em momento algum. Para tal, precisamos criar uma Transaction, ou seja, uma transação junto ao banco de dados do AutoCAD, e assim inserir efetivamente os objetos nele.

Devemos agora desenhar o quadrado. A primeira medida a ser tomada agora é adicionar o namespace Autodesk.AutoCAD.ApplicationServices. Esse namespace nos fornecerá um método para acessarmos o documento corrente do AutoCAD, isto é, o documento que está aberto e ativo no programa.

Após isso, criamos a Transaction usando o método StartTransaction() do campo TransactionManager. Como a classe Transaction herda de RXObject, que herda de DisposableWrapper, que herda de IDisposable (ufa...), é possível usar a keyword "using", que descartará o objeto ao fim do bloco (mais informações sobre a keyword using aqui: http://msdn.microsoft.com/en-us/library/yh598w02.aspx).

Dentro deste bloco, iremos invocar o método GetObject do nosso objeto de transação, que lê um objeto do banco de dados. Este método, portanto, recebe um ObjectId, e o método de abertura (ForRead, ForWrite, ForNotify - geralmente, nós usamos ou ForRead, quando queremos apenas ler o objeto, ou ForWrite quando quisermos alterar o banco de alguma forma).

Agora, nós iremos ler a tabela de blocos (BlockTable), que vai conter as retas criadas por nós. Após este passo, iremos ler o ModelSpace, e abri-lo para escrita, para que possamos inserir nossos objetos de fato:

{% highlight csharp linenos %}
            var document = Application.DocumentManager.MdiActiveDocument;
 
            using (var transaction = document.TransactionManager.StartTransaction())
            {
                var blockTable = transaction.GetObject(document.Database.BlockTableId, OpenMode.ForRead) as BlockTable;
                var blockTableRecord = transaction.GetObject(blockTable[BlockTableRecord.ModelSpace], OpenMode.ForWrite) as BlockTableRecord;                
            }
{% endhighlight %}

Precisamos agora adicionar as quatro retas ao modelo. Iremos usar dois métodos para tal: AppendEntity(Entity) e AddNewlyCreatedDBObject(DBObject, bool), que pertencem, respectivamente, às classes BlockTableRecord e Transaction. Após adicionamos, nós executamos a transação com o método Commit():


{% highlight csharp linenos %}
                blockTableRecord.AppendEntity(retaAB);
                transaction.AddNewlyCreatedDBObject(retaAB, true);
 
                blockTableRecord.AppendEntity(retaAC);
                transaction.AddNewlyCreatedDBObject(retaAC, true);
 
                blockTableRecord.AppendEntity(retaBD);
                transaction.AddNewlyCreatedDBObject(retaBD, true);
 
                blockTableRecord.AppendEntity(retaCD);
                transaction.AddNewlyCreatedDBObject(retaCD, true);
 
                transaction.Commit();
{% endhighlight %}

Pronto. Agora, apenas por motivos estéticos, iremos escrever no output do AutoCAD que nosso comando teve êxito na execução. Para isto, basta executar o método WriteMessage do campo Editor do nosso documento. Abaixo, o código completo do nosso gerador de quadrados: 


{% highlight csharp linenos %}
using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Geometry;
using Autodesk.AutoCAD.Runtime;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
 
namespace DesenharQuadrado
{
    public class AuxiliarAutoCAD
    {
        [CommandMethod("DesenharQuadrado")]
        public void DesenharQuadrado()
        {
 
            var pontoA = new Point3d(0, 100, 0);
            var pontoB = new Point3d(100, 100, 0);
            var pontoC = new Point3d(0, 0, 0);
            var pontoD = new Point3d(100, 0, 0);
 
            var retaAB = new Line(pontoA, pontoB);
            var retaAC = new Line(pontoA, pontoC);
            var retaBD = new Line(pontoB, pontoD);
            var retaCD = new Line(pontoC, pontoD);
 
            var document = Application.DocumentManager.MdiActiveDocument;
 
            using (var transaction = document.TransactionManager.StartTransaction())
            {
                var blockTable = transaction.GetObject(document.Database.BlockTableId, OpenMode.ForRead) as BlockTable;
                var blockTableRecord = transaction.GetObject(blockTable[BlockTableRecord.ModelSpace], OpenMode.ForWrite) as BlockTableRecord;
 
                blockTableRecord.AppendEntity(retaAB);
                transaction.AddNewlyCreatedDBObject(retaAB, true);
 
                blockTableRecord.AppendEntity(retaAC);
                transaction.AddNewlyCreatedDBObject(retaAC, true);
 
                blockTableRecord.AppendEntity(retaBD);
                transaction.AddNewlyCreatedDBObject(retaBD, true);
 
                blockTableRecord.AppendEntity(retaCD);
                transaction.AddNewlyCreatedDBObject(retaCD, true);
 
                transaction.Commit();
 
                transaction.Commit();
            }
 
            document.Editor.WriteMessage("Comando efetuado com sucesso.");
        }
    }
}
{% endhighlight %}


Agora, vamos à compilação. Uma coisa que é interessante fazer em se tratando das DLLs do ObjectArx é marcar a opção de copiar para a pasta do build como falsa (obrigado ao Augusto Gonçalves da Autodesk por me lembrar disso :D ). Para tal, basta clicar na referência da DLL e marcar a caixa de opções como a seguir:

![Fig. 6 Compilando]({{ site_url }}/images/desenhando-de-maneira-programtica-no-autocad-introduo.img6.png)

Agora, utilizando a técnica descrita por nós [anteriormente]({{ site_url }}/posts/configurando-o-visual-studio-2012-express-para-debugar-o-autocad-2013/), iremos iniciar a nossa aplicação. Clique em Start , ou aperte F5, para iniciar a depuração (debug):

![Fig. 7]({{ site_url }}/images/desenhando-de-maneira-programtica-no-autocad-introduo.img7.png)

Lembre-se que precisamos digitar o comando netload no AutoCAD e carregarmos nossa biblioteca recém-escrita. Ela se encontra na pasta bin/Debug do projeto:

![Fig. 8 NETLOAD]({{ site_url }}/images/desenhando-de-maneira-programtica-no-autocad-introduo.img8.png)

Agora, podemos executar nosso comando DesenharQuadrado dentro do AutocCAD:

![Fig. 9]({{ site_url }}/images/desenhando-de-maneira-programtica-no-autocad-introduo.img9.png)


E então observamos o resultado: um quadrado desenhado na origem, com lado 100:

![Fig. 10 Pronto! Um quadrado apareceu na tela.]({{ site_url }}/images/desenhando-de-maneira-programtica-no-autocad-introduo.img10.png)

Enfim, é isso. O post é longo pois vários conceitos novos foram abordados aqui. Mas pode-se observar que não é uma tarefa muito difícil desenhar no AutoCAD. Apesar de ser uma ferramenta de desenho bastante completa, não é possível para a Autodesk inferir todos os usos que seu aplicativo possa ter. Portanto, criar comandos como este podem facilitar bastante a vida de arquitetos e engenheiros que precisem de algo mais específico.

Abraço e até a próxima.
