package com.example.bdget.repository;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.util.List;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;

import com.example.bdget.model.Student;

// Prueba de integracion de la capa de persistencia contra H2 en memoria
@DataJpaTest
class StudentRepositoryTest {

    @Autowired
    private StudentRepository repository;

    @BeforeEach
    void setUp() {
        repository.deleteAll();
        repository.save(student("Valentina"));
        repository.save(student("Michelle"));
        repository.save(student("Martina"));
    }

    @Test
    void testFindByNameContainingIgnoreCase() {
        List<Student> result = repository.findByNameContainingIgnoreCase("TINA");
        assertEquals(2, result.size());
    }

    @Test
    void testCount() {
        assertEquals(3, repository.count());
    }

    private Student student(String name) {
        Student s = new Student();
        s.setName(name);
        return s;
    }
}
