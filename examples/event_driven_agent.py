"""
Event-Driven Agent Pattern Example
Demonstrates Kafka producer/consumer for async agent communication
"""
import os
import json
import logging
from kafka import KafkaProducer, KafkaConsumer
from kafka.errors import KafkaError

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

KAFKA_BROKER = os.getenv("KAFKA_BROKER", "localhost:29092")
AGENT_EVENTS_TOPIC = "agent-events"

# Producer Example
class AgentEventProducer:
    """Publish agent events to Kafka"""
    
    def __init__(self):
        self.producer = KafkaProducer(
            bootstrap_servers=KAFKA_BROKER,
            value_serializer=lambda v: json.dumps(v).encode('utf-8')
        )
    
    def publish_agent_started(self, agent_id: str, task: str):
        event = {
            "event_type": "agent.started",
            "agent_id": agent_id,
            "task": task,
            "timestamp": "2024-01-01T00:00:00Z"
        }
        future = self.producer.send(AGENT_EVENTS_TOPIC, value=event)
        try:
            record_metadata = future.get(timeout=10)
            logger.info(f"Event sent: {record_metadata.topic}:{record_metadata.partition}:{record_metadata.offset}")
        except KafkaError as e:
            logger.error(f"Failed to send event: {e}")
    
    def publish_agent_completed(self, agent_id: str, result: dict):
        event = {
            "event_type": "agent.completed",
            "agent_id": agent_id,
            "result": result,
            "timestamp": "2024-01-01T00:00:00Z"
        }
        self.producer.send(AGENT_EVENTS_TOPIC, value=event)
        logger.info(f"Agent {agent_id} completion event published")


# Consumer Example
class AgentEventConsumer:
    """Subscribe to agent events from Kafka"""
    
    def __init__(self, group_id="agent-monitor"):
        self.consumer = KafkaConsumer(
            AGENT_EVENTS_TOPIC,
            bootstrap_servers=KAFKA_BROKER,
            group_id=group_id,
            value_deserializer=lambda m: json.loads(m.decode('utf-8')),
            auto_offset_reset='earliest'
        )
    
    def process_events(self):
        logger.info("Listening for agent events...")
        for message in self.consumer:
            event = message.value
            logger.info(f"Received: {event['event_type']} - Agent: {event.get('agent_id')}")
            
            # Handle different event types
            if event["event_type"] == "agent.started":
                self.handle_agent_started(event)
            elif event["event_type"] == "agent.completed":
                self.handle_agent_completed(event)
    
    def handle_agent_started(self, event):
        logger.info(f"Agent {event['agent_id']} started task: {event['task']}")
    
    def handle_agent_completed(self, event):
        logger.info(f"Agent {event['agent_id']} completed with result: {event['result']}")


# Example usage
if __name__ == "__main__":
    # Producer example
    producer = AgentEventProducer()
    producer.publish_agent_started("agent-001", "Analyze customer sentiment")
    producer.publish_agent_completed("agent-001", {"sentiment": "positive", "score": 0.85})
    
    # Consumer example (run in separate process)
    # consumer = AgentEventConsumer()
    # consumer.process_events()
