package com.example.bdget;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.Mockito.mockStatic;

import org.junit.jupiter.api.Test;
import org.mockito.MockedStatic;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.ApplicationContext;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class BdgetApplicationTests {

        @Autowired
        private ApplicationContext context;

        @Test
        void contextLoads() {
                assertNotNull(context);
        }

        // Verifica el punto de entrada sin levantar una segunda aplicacion que quede abierta
        @Test
        void mainStartsSpringApplication() {
                String[] args = {"--server.port=0"};
                try (MockedStatic<SpringApplication> spring = mockStatic(SpringApplication.class)) {
                        BdgetApplication.main(args);
                        spring.verify(() -> SpringApplication.run(BdgetApplication.class, args));
                }
        }

}
