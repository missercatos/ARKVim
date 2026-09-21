-- arkvim/scaffold/java.lua — Java 模板
local util = require("arkvim.scaffold.util")
local mkdir_p = util.mkdir_p

local M = {}
local gen = {}

gen.springboot = function(target, name)
  local t = util.project_tokens(name)
  mkdir_p(target)
  local zip = vim.fn.tempname() .. ".zip"
  local url = string.format(
    "https://start.spring.io/starter.zip?type=maven-project&language=java"
      .. "&groupId=com.example&artifactId=%s&name=%s&packageName=%s"
      .. "&packaging=jar&javaVersion=17&dependencies=web,devtools,validation,lombok",
    t.kebab, t.NAME, t.pkg)
  vim.fn.system({ "curl", "-fsSL", "--max-time", "90", "-o", zip, url })
  if vim.v.shell_error == 0 and vim.fn.filereadable(zip) == 1 then
    local ok = util.unzip_strip(zip, target)
    if ok then
      vim.fn.system({ "rm", "-f", zip })
      return "Spring Boot 已生成"
    end
  end
  vim.fn.system({ "rm", "-f", zip })
  local files = {
    ["pom.xml"] = util.fill([[<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>3.3.5</version>
    <relativePath/>
  </parent>
  <groupId>com.example</groupId>
  <artifactId>{{kebab}}</artifactId>
  <version>0.0.1-SNAPSHOT</version>
  <name>{{NAME}}</name>
  <properties><java.version>17</java.version></properties>
  <dependencies>
    <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-web</artifactId></dependency>
    <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-test</artifactId><scope>test</scope></dependency>
  </dependencies>
  <build><plugins>
    <plugin><groupId>org.springframework.boot</groupId><artifactId>spring-boot-maven-plugin</artifactId></plugin>
  </plugins></build>
</project>]], t),
    [("src/main/java/com/example/%s/%sApplication.java"):format(t.snake, t.Pascal)] = util.fill([[
package com.example.{{snake}};
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
@SpringBootApplication @RestController
public class {{Pascal}}Application {
  public static void main(String[] args) { SpringApplication.run({{Pascal}}Application.class, args); }
  @GetMapping("/") public String hello() { return "Hello from {{NAME}}!"; }
}]], t),
    ["src/main/resources/application.yml"] = "server:\n  port: 8080\n",
    [".gitignore"] = "target/\n*.class\n*.jar\n.idea/\n*.iml\n",
    ["README.md"] = util.fill("# {{NAME}}\n\n```bash\nmvn spring-boot:run\n```\n", t),
  }
  util.write_tree(target, files)
  return "Spring Boot (离线骨架) 已生成"
end

gen.quarkus = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["pom.xml"] = util.fill([[
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.example</groupId>
  <artifactId>{{kebab}}</artifactId>
  <version>1.0.0-SNAPSHOT</version>
  <properties>
    <maven.compiler.source>17</maven.compiler.source>
    <maven.compiler.target>17</maven.compiler.target>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    <quarkus.platform.group-id>io.quarkus.platform</quarkus.platform.group-id>
    <quarkus.platform.artifact-id>quarkus-bom</quarkus.platform.artifact-id>
    <quarkus.platform.version>3.8.0</quarkus.platform.version>
  </properties>
  <dependencyManagement>
    <dependencies>
      <dependency>
        <groupId>${quarkus.platform.group-id}</groupId>
        <artifactId>${quarkus.platform.artifact-id}</artifactId>
        <version>${quarkus.platform.version}</version>
        <type>pom</type>
        <scope>import</scope>
      </dependency>
    </dependencies>
  </dependencyManagement>
  <dependencies>
    <dependency><groupId>io.quarkus</groupId><artifactId>quarkus-rest</artifactId></dependency>
    <dependency><groupId>io.quarkus</groupId><artifactId>quarkus-junit5</artifactId><scope>test</scope></dependency>
  </dependencies>
  <build><plugins>
    <plugin><groupId>io.quarkus</groupId><artifactId>quarkus-maven-plugin</artifactId>
      <version>${quarkus.platform.version}</version>
      <executions><execution><goals><goal>build</goal><goal>generate-code</goal><goal>generate-code-tests</goal></goals></execution></executions>
    </plugin>
  </plugins></build>
</project>]], t),
    ["src/main/java/com/example/" .. t.snake .. "/GreetingResource.java"] = util.fill('package com.example.{{snake}};\n\nimport jakarta.ws.rs.GET;\nimport jakarta.ws.rs.Path;\nimport jakarta.ws.rs.Produces;\nimport jakarta.ws.rs.core.MediaType;\n\n@Path("/hello")\npublic class GreetingResource {\n    @GET\n    @Produces(MediaType.APPLICATION_JSON)\n    public String hello() {\n        return "{\\"message\\": \\"Hello from {{NAME}}!\\"}";\n    }\n}\n', t),
    ["src/main/resources/application.yml"] = "quarkus:\n  http:\n    port: 8080\n",
    [".gitignore"] = "target/\n*.class\n*.jar\n.idea/\n*.iml\n",
  })
  return "Quarkus (Java) 已生成"
end

gen.micronaut = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["pom.xml"] = util.fill([[<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <parent>
    <groupId>io.micronaut.platform</groupId>
    <artifactId>micronaut-parent</artifactId>
    <version>4.3.0</version>
  </parent>
  <groupId>com.example</groupId>
  <artifactId>{{kebab}}</artifactId>
  <version>0.1</version>
  <properties><packaging>jar</packaging><jdk.version>17</jdk.version></properties>
  <dependencies>
    <dependency><groupId>io.micronaut</groupId><artifactId>micronaut-http-server-netty</artifactId></dependency>
    <dependency><groupId>io.micronaut</groupId><artifactId>micronaut-http-client</artifactId></dependency>
  </dependencies>
</project>]], t),
    [("src/main/java/com/example/%s/Application.java"):format(t.snake)] = util.fill([[
package com.example.{{snake}};
import io.micronaut.runtime.Micronaut;
public class Application {
    public static void main(String[] args) { Micronaut.run(Application.class, args); }
}]], t),
    [("src/main/java/com/example/%s/HelloController.java"):format(t.snake)] = util.fill([[
package com.example.{{snake}};
import io.micronaut.http.annotation.*;
@Controller("/hello")
public class HelloController {
    @Get
    public String index() { return "Hello from {{NAME}}!"; }
}]], t),
    ["src/main/resources/application.yml"] = "micronaut:\n  application:\n    name: " .. t.kebab .. "\n  server:\n    port: 8080\n",
    [".gitignore"] = "target/\n",
  })
  return "Micronaut (Java) 已生成"
end

gen.javacli = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["src/" .. t.snake .. "/Main.java"] = util.fill("package {{snake}};\npublic class Main {\n  public static void main(String[] args) {\n    System.out.println(\"Hello from {{NAME}}!\");\n  }\n}\n", t),
    ["Makefile"] = ("JAVAC := javac\nJAVA  := java\n\nbuild:\n\t$(JAVAC) -d out src/%s/Main.java\n\nrun: build\n\t$(JAVA) -cp out %s.Main\n\n.PHONY: build run\n"):format(t.snake, t.snake),
    [".gitignore"] = "out/\n*.class\n",
  })
  return "Java CLI 已生成"
end

-- JavaFX: Maven + javafx-maven-plugin
gen.javafx = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["pom.xml"] = util.fill([[<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.example</groupId>
  <artifactId>{{kebab}}</artifactId>
  <version>1.0.0</version>
  <properties>
    <maven.compiler.source>17</maven.compiler.source>
    <maven.compiler.target>17</maven.compiler.target>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    <javafx.version>21.0.2</javafx.version>
  </properties>
  <dependencies>
    <dependency><groupId>org.openjfx</groupId><artifactId>javafx-controls</artifactId><version>${javafx.version}</version></dependency>
    <dependency><groupId>org.openjfx</groupId><artifactId>javafx-fxml</artifactId><version>${javafx.version}</version></dependency>
  </dependencies>
  <build><plugins>
    <plugin>
      <groupId>org.openjfx</groupId>
      <artifactId>javafx-maven-plugin</artifactId>
      <version>0.0.8</version>
      <configuration><mainClass>com.example.{{snake}}.App</mainClass></configuration>
    </plugin>
  </plugins></build>
</project>]], t),
    [("src/main/java/com/example/%s/App.java"):format(t.snake)] = util.fill([[
package com.example.{{snake}};
import javafx.application.Application;
import javafx.scene.Scene;
import javafx.scene.control.Label;
import javafx.scene.layout.StackPane;
import javafx.stage.Stage;

public class App extends Application {
    @Override
    public void start(Stage stage) {
        Label label = new Label("Hello from {{NAME}}!");
        Scene scene = new Scene(new StackPane(label), 640, 400);
        stage.setTitle("{{NAME}}");
        stage.setScene(scene);
        stage.show();
    }
    public static void main(String[] args) { launch(args); }
}]], t),
    [("src/main/java/module-info.java")] = util.fill("module com.example.{{snake}} {\n    requires javafx.controls;\n    requires javafx.fxml;\n    exports com.example.{{snake}};\n}\n", t),
    [".gitignore"] = "target/\n",
    ["README.md"] = util.fill("# {{NAME}}\n\n```bash\nmvn javafx:run\n```\n", t),
  })
  return "JavaFX 已生成"
end

-- Swing: 零依赖，javac 直接跑
gen.swing = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["src/" .. t.snake .. "/App.java"] = util.fill([[
package {{snake}};
import javax.swing.*;
public class App {
    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> {
            JFrame frame = new JFrame("{{NAME}}");
            frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
            frame.add(new JLabel("Hello from {{NAME}}!", SwingConstants.CENTER));
            frame.setSize(640, 400);
            frame.setLocationRelativeTo(null);
            frame.setVisible(true);
        });
    }
}]], t),
    ["Makefile"] = ("JAVAC := javac\nJAVA  := java\n\nbuild:\n\t$(JAVAC) -d out src/%s/App.java\n\nrun: build\n\t$(JAVA) -cp out %s.App\n\n.PHONY: build run\n"):format(t.snake, t.snake),
    [".gitignore"] = "out/\n*.class\n",
  })
  return "Java Swing 已生成"
end

M.frameworks = {
  { label = "Spring Boot (Java)", lang = "java", gen = gen.springboot, main = "pom.xml",
    requires = { bins = { "mvn", "java" }, pacman = { "maven", "jdk-openjdk" } } },
  { label = "Quarkus (Java)", lang = "java", gen = gen.quarkus, main = "pom.xml",
    requires = { bins = { "mvn", "java" }, pacman = { "maven", "jdk-openjdk" } } },
  { label = "Micronaut (Java)", lang = "java", gen = gen.micronaut, main = "pom.xml",
    requires = { bins = { "mvn", "java" }, pacman = { "maven", "jdk-openjdk" } } },
  { label = "JavaFX (Java)", lang = "java", gen = gen.javafx,
    main = function(n) return "src/main/java/com/example/" .. util.snake(n) .. "/App.java" end,
    requires = { bins = { "mvn", "java" }, pacman = { "maven", "jdk-openjdk" }, note = "运行: mvn javafx:run" } },
  { label = "Swing GUI (Java)", lang = "java", gen = gen.swing, main = "",
    requires = { bins = { "javac", "java" }, pacman = { "jdk-openjdk" } } },
  { label = "Java CLI (javac)", lang = "java", gen = gen.javacli, main = "",
    requires = { bins = { "javac", "java" }, pacman = { "jdk-openjdk" } } },
}

return M
