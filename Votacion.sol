// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Votacion {
    
    // Estructura para guardar información de cada candidato
    struct Candidato {
        uint id;
        string nombre;
        uint cantidadVotos;
    }
    
    // Estructura para guardar información de cada votante
    struct Votante {
        bool estaRegistrado;
        bool yaVoto;
        uint votoParaCandidato;
    }

    // Variable para el administrador del contrato
    address public owner;

    // Base de datos de candidatos (usa el ID como clave)
    mapping(uint => Candidato) public candidatos;

    // Base de datos de votantes (usa la dirección de wallet como clave)
    mapping(address => Votante) public votantes;

    // Tiempos de inicio y fin de la votación
    uint public inicioVotacion;
    uint public finVotacion;

    // "Candado" de seguridad: Solo el dueño puede usar funciones con esto
    modifier onlyOwner() {
        require(msg.sender == owner, "Solo el administrador puede hacer esto");
        _;
    }

    // Función especial que se ejecuta al crear el contrato
    constructor(string[] memory _nombresCandidatos, uint _duracionEnSegundos) {
        owner = msg.sender; // El que crea el contrato es el dueño
        inicioVotacion = block.timestamp; // Empieza ahora
        finVotacion = block.timestamp + _duracionEnSegundos; // Termina en X segundos

        // Agregamos los candidatos a la lista
        for (uint i = 0; i < _nombresCandidatos.length; i++) {
            candidatos[i] = Candidato({
                id: i,
                nombre: _nombresCandidatos[i],
                cantidadVotos: 0
            });
        }
    }
    // Función para registrar un votante autorizado
    function registerVoter(address _voter) public onlyOwner {
        //Verificamos que esa persona NO esté ya registrada. El ! significa "no". 
        //Si ya está registrada, mostramos error y detenemos la ejecución.
        require(!votantes[_voter].estaRegistrado, "Este votante ya esta registrado");//
        //Creamos la Ficha del votante
        votantes[_voter] = Votante({
            estaRegistrado: true,
            yaVoto: false,
            votoParaCandidato: 99999 // Valor por defecto, sin significado
        });
    } 


    // Función para que un votante emita su voto
    function vote(uint _candidateId) public {
        // 1. Verificar que la votación esté en curso
        //¿Ya empezó la votación? Si no, error.
        require(block.timestamp >= inicioVotacion, "La votacion aun no ha iniciado");
        
        //¿Aún no termina? Si ya pasó la fecha, error.
        require(block.timestamp <= finVotacion, "La votacion ya ha finalizado");
        
        // 2. Verificar que el votante esté registrado ¿Esta wallet está en la lista de autorizados? Si no, error.
        require(votantes[msg.sender].estaRegistrado, "No estas autorizado para votar");
        
        // 3. Verificar que no haya votado antes ¿Ya votó antes? Si sí, error (evita doble voto).
        require(!votantes[msg.sender].yaVoto, "Ya has emitido tu voto");
        
        // 4. Verificar que el candidato exista ¿El ID del candidato existe en nuestra lista? Si no, error.
        require(candidatos[_candidateId].id == _candidateId, "Candidato no valido");
        
        // 5. Registrar el voto
        votantes[msg.sender].yaVoto = true;
        votantes[msg.sender].votoParaCandidato = _candidateId;
        candidatos[_candidateId].cantidadVotos += 1;

        //Cada vez que alguien vota, la blockchain guarda un registro especial (evento) 
        //que dice "La dirección X votó por el candidato Y". 
        //Esto permite auditar el proceso sin revelar el voto secreto (si así se diseñara), 
        //pero en este caso, sirve para trazabilidad pública
              
        emit VotoRegistrado(msg.sender, _candidateId);
    } 

    // Eventos para auditoría y transparencia
    event VotoRegistrado(address indexed votante, uint indexed candidatoId);
    event VotanteRegistrado(address indexed votante);
    event VotacionFinalizada(string razon);  

    // Función para ver resultados de todos los candidatos
    function getResults() public view returns (
        uint[] memory ids,
        string[] memory nombres,
        uint[] memory votos
    ) {
        // Declaro contador de candidatos
        uint cantidadCandidatos = 0;
        
        // Contar cuántos candidatos hay
        for (uint i = 0; i < 100; i++) {
            if (candidatos[i].id == i) {
                cantidadCandidatos++;
            } else {
                break;
            }
        }
        
        // Crear arrays para devolver los datos
        ids = new uint[](cantidadCandidatos);
        nombres = new string[](cantidadCandidatos);
        votos = new uint[](cantidadCandidatos);
        
        // Llenar los arrays con la información
        for (uint i = 0; i < cantidadCandidatos; i++) {
            ids[i] = candidatos[i].id;
            nombres[i] = candidatos[i].nombre;
            votos[i] = candidatos[i].cantidadVotos;
        }
        
        return (ids, nombres, votos);
    } 

    // Función para consultar el estado de un votante
    function getVoterInfo(address _voter) public view returns (
        bool estaRegistrado,
        bool yaVoto,
        uint votoParaCandidato
    ) {
        return (
            votantes[_voter].estaRegistrado,
            votantes[_voter].yaVoto,
            votantes[_voter].votoParaCandidato
        );
    }        
    // Función para finalizar la votación anticipadamente
    function endVoting() public onlyOwner {
        require(block.timestamp < finVotacion, "La votacion ya termino");
        
        finVotacion = block.timestamp; // Cierra la urna ahora mismo
        emit VotacionFinalizada("Finalizada anticipadamente por el administrador");
    }
}