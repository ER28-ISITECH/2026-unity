using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.AI;

public class Enemy : MonoBehaviour
{
    // Stats de l'ennemi
    [SerializeField] float damage = 10;
    [SerializeField] float enemyHP = 100;
    [SerializeField] float moveSpeed = 2f;
    [SerializeField] float stoppingDistance = 1f;
    [SerializeField] Transform target;
    [SerializeField] Transform enemyOrientation;

    //Animator animator;
    NavMeshAgent agent;
    //BoxCollider damageBox;
    //Rigidbody rb;
    monsterSpawner Spawner;

    void Start()
    {
        agent = GetComponent<NavMeshAgent>();

        // Configuration de l'agent NavMesh
        if (agent != null)
        {
            agent.speed = moveSpeed;
            agent.stoppingDistance = stoppingDistance;
            agent.SetDestination(target.position); // Définit la destination initiale
        }
    }

    void Update()
    {
        // Si l'ennemi a encore des HP et une cible
        if (enemyHP > 0 && target != null && agent != null)
        {
            // Met à jour la destination de l'agent
            agent.SetDestination(target.position);

            // Vérifie si l'ennemi a atteint sa destination
            if (!agent.pathPending && agent.remainingDistance <= agent.stoppingDistance)
            {
                Debug.Log("L'ennemi a atteint sa cible !");
                // logique d'attaque ou d'animation
            }
        }
        else if (enemyHP <= 0)
        {
            KillEnemy();
        }
    }

    // Méthode pour infliger des dégâts à l'ennemi
    public void TakeDamage(float damageAmount)
    {
        enemyHP -= damageAmount;
        Debug.Log("L'ennemi a reçu " + damageAmount + " dégâts ! Il lui reste " + enemyHP + " HP.");
    }

    void KillEnemy()
    {
        if (Spawner != null)
            Spawner.currentMonster.Remove(this.gameObject);
        Destroy(gameObject);
    }

    public void SetSpawner(monsterSpawner _spawner)
    {
        Spawner = _spawner;
    }

    // Méthode pour définir la cible (ex: le joueur)
    public void SetTarget(Transform newTarget)
    {
        target = newTarget;
        if (agent != null)
            agent.SetDestination(target.position);
    }

    public void SetTargetPosition(Vector3 targetPosition)
    {
        if (agent != null)
        {
            // Crée un GameObject temporaire pour stocker la position
            GameObject tempTarget = new GameObject("TempTarget");
            tempTarget.transform.position = targetPosition;
            target = tempTarget.transform;
            agent.SetDestination(targetPosition);
        }
    }
}