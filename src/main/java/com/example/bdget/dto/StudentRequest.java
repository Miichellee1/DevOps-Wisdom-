package com.example.bdget.dto;

import com.example.bdget.model.Student;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

// DTO de entrada: evita exponer la entidad JPA directamente en la API (mass assignment)
public record StudentRequest(
        @Pattern(regexp = "^[a-zA-Z]+$", message = "El nombre solo puede contener letras")
        @Size(min = 2, max = 50, message = "El nombre debe tener entre 2 y 50 caracteres")
        @NotBlank(message = "No puede ingresar un nombre vacio")
        String name) {

    public Student toEntity() {
        Student student = new Student();
        student.setName(name);
        return student;
    }
}
