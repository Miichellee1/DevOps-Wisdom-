package com.example.bdget;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class BdgetApplicationTests {

        @Test
        void contextLoads() {
                BdgetApplication.main(new String[]{"--server.port=0"});
        }

}
