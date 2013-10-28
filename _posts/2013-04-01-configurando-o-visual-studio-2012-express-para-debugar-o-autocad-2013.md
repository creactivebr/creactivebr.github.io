---
layout: post
title: "Configurando o Visual Studio 2012 Express para Debugar o AutoCAD 2013"
category: posts
author: brunosaboia
tags: [ Autocad, Visual Studio, Debug ]
---

Um aspecto primordial da programação em geral diz respeito à configuração do ambiente. No nosso caso, configurar o Visual Studio para habilitar o debug quando estivermos escrevendo plug-ins para o AutoCAD é fundamental.
Para isso, vamos criar um novo projeto (lembre-se: um plug-in de AutoCAD é do tipo Class Library):

![Imagem 1]({{ site_url }}/images/configurando-o-visual-studio-2012-express-para-debugar-o-autocad-2013.img1.png)

Nas versões Express do Visual Studio, não há maneira de configurar o programa que irá iniciar o Debug. Porém, há um pequeno truque para contornarmos essa situação.

Para isso, feche o Visual Studio Express e vá até a pasta do projeto:

![Imagem 2]({{ site_url }}/images/configurando-o-visual-studio-2012-express-para-debugar-o-autocad-2013.img2.png)

Você deverá ver esses arquivos. Crie um novo arquivo no padrão (NomeDoProjeto).csproj.user. No nosso caso, o arquivo deverá se chamar FirstAutoCADApp.csproj.user:

![Imagem 2]({{ site_url }}/images/configurando-o-visual-studio-2012-express-para-debugar-o-autocad-2013.img3.png)
  
Após isso, edite o arquivo que você acabou de criar usando o notepad, o Visual Studio ou qualquer outro editor de texto que você prefira.
Insira o seguinte conteúdo nele:

{% highlight xml linenos=table %}
<?xml version="1.0" encoding="utf-8"?>
<Project ToolsVersion="4.0" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <PropertyGroup Condition="'$(Configuration)|$(Platform)' == 'Debug|AnyCPU'">
    <StartAction>Program</StartAction>
    <StartProgram>C:\Program Files\Autodesk\AutoCAD 2013\acad.exe</StartProgram>
    <StartWorkingDirectory>C:\Program Files\Autodesk\AutoCAD 2013\</StartWorkingDirectory>
  </PropertyGroup>
</Project>
{% endhighlight %}

Lembre-se de trocar o caminho “C:\Program Files\Autodesk\AutoCAD 2013” pelo caminho onde você instalou o AutoCAD 2013.
Salve o arquivo e reabra o Visual Studio Express. Agora, ao ir em DEBUG -> Start Debugging (ou simplesmente ao apertar F5) o AutoCAD abrirá, permitindo que você debugue sua aplicação. 

No próximo tópico eu irei mostrar um exemplo prático disso.

Uma última observação: é possível editar essas configurações diretamente no arquivo .csproj, sem a necessidade de criar um .user, mas eu acho que criar um novo arquivo deixa o ambiente muito mais organizado. Eu não irei cobrir aqui como fazer editando diretamente o .csproj.

Boa sorte, e bom desenvolvimento a todos!