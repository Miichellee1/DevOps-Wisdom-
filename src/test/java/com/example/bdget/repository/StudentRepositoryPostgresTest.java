package com.example.bdget.repository;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

import java.util.List;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import com.example.bdget.model.Student;

// Prueba de integracion contra la misma base de datos que produccion (PostgreSQL 16),
// levantada en un contenedor efimero por Testcontainers
@DataJpaTest
@Testcontainers
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
class StudentRepositoryPostgresTest {

    @Container
    @ServiceConnection
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine");

    @Autowired
    private StudentRepository repository;

    @BeforeEach
    void setUp() {
        repository.deleteAll();
    }

    @Test
    void testSaveAndFindByIdInPostgres() {
        Student student = new Student();
        student.setName("Valentina");
        Student saved = repository.save(student);

        assertNotNull(saved.getId());
        assertEquals("Valentina", repository.findById(saved.getId()).orElseThrow().getName());
    }

    @Test
    void testFindByNameContainingIgnoreCaseInPostgres() {
        for (String name : List.of("Valentina", "Michelle", "Martina")) {
            Student student = new Student();
            student.setName(name);
            repository.save(student);
        }

        assertEquals(2, repository.findByNameContainingIgnoreCase("TINA").size());
        assertEquals(3, repository.count());
    }
}
